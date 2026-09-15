'use strict';

// Called by iOS immediately after a successful StoreKit 2 purchase.
// The iOS app passes the signed JWS transaction string from StoreKit.
// We decode and record it, then set hasCommunityAccess=true on the user.
//
// This is the primary grant path (synchronous, user is waiting). The Apple
// webhook (appleWebhook Lambda) is the async backup for edge cases (app
// crash, network failure after purchase).

const { GetCommand, PutCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

const COMMUNITY_PRODUCT_ID = 'com.lifemaxxing.app.community_creation';
const NINETY_DAYS_S = 90 * 24 * 60 * 60;

function decodeJWSPayload(jws) {
  const parts = jws.split('.');
  if (parts.length !== 3) throw new Error('Invalid JWS format');
  const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
  const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4);
  return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
}

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return http.badRequest('Request body must be valid JSON');
  }

  const { signedTransactionInfo } = body;
  if (!signedTransactionInfo || typeof signedTransactionInfo !== 'string') {
    return http.badRequest('signedTransactionInfo (string) is required');
  }

  let txPayload;
  try {
    txPayload = decodeJWSPayload(signedTransactionInfo);
  } catch {
    return http.badRequest('Invalid signed transaction JWS');
  }

  const { productId, transactionId, bundleId } = txPayload;

  if (bundleId !== (process.env.APPLE_BUNDLE_ID || 'com.lifemaxxing.app')) {
    return http.badRequest('Bundle ID mismatch');
  }
  if (productId !== COMMUNITY_PRODUCT_ID) {
    return http.badRequest('Unexpected productId: ' + productId);
  }
  if (!transactionId) {
    return http.badRequest('Transaction ID missing from signed payload');
  }

  // Ensure the user exists
  const { Item: user } = await ddb.send(new GetCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
  }));
  if (!user) return http.notFound('User profile not found');

  // Deduplicate: if this transactionId was already processed, still return success
  const pk = `TRANSACTION#${transactionId}`;
  const ttl = Math.floor(Date.now() / 1000) + NINETY_DAYS_S;

  try {
    await ddb.send(new PutCommand({
      TableName: TableNames.PURCHASE_EVENTS,
      Item: { PK: pk, userSub, transactionId, grantedAt: new Date().toISOString(), ttl },
      ConditionExpression: 'attribute_not_exists(PK)',
    }));
  } catch (err) {
    if (err.name !== 'ConditionalCheckFailedException') throw err;
    // Already processed — still return success so the app can proceed
    return http.ok({ hasCommunityAccess: true });
  }

  await ddb.send(new UpdateCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
    UpdateExpression: 'SET hasCommunityAccess = :t',
    ExpressionAttributeValues: { ':t': true },
  }));

  console.log(JSON.stringify({ msg: 'purchase verified', userSub, transactionId, productId }));
  return http.ok({ hasCommunityAccess: true });
};
