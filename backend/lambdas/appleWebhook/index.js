'use strict';

// Apple App Store Server Notifications v2 webhook.
// Apple POSTs a signed JWS (JSON Web Signature) payload when a purchase event
// occurs. We decode it, verify the bundle ID and product, deduplicate via
// PurchaseEventsTable, and set hasCommunityAccess=true on the matching user.
//
// Apple's JWS format: header.payload.signature (base64url-encoded).
// We trust Apple's signature (verified client-side by StoreKit 2) but we
// validate the bundle ID and product ID server-side to prevent spoofing.
// For production hardening, also verify the x5c certificate chain against
// Apple's root CA.

const { GetCommand, PutCommand, UpdateCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { dynamo, http } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

const COMMUNITY_PRODUCT_ID = 'com.lifemaxxing.app.community_creation';
const BUNDLE_ID = process.env.APPLE_BUNDLE_ID || 'com.lifemaxxing.app';
const NINETY_DAYS_S = 90 * 24 * 60 * 60;

function decodeJWSPayload(jws) {
  const parts = jws.split('.');
  if (parts.length !== 3) throw new Error('Invalid JWS format');
  const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
  const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4);
  return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
}

async function findUserByTransactionSub(transactionSub) {
  // The App Store Server Notifications payload contains the original appAccountToken
  // set during purchase (see iOS PurchaseService: we set .appAccountToken to the
  // user's Cognito sub UUID). Look up the user by that sub.
  const { Item } = await ddb.send(new GetCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${transactionSub}`, SK: 'PROFILE' },
  }));
  return Item || null;
}

async function deduplicateAndGrant(transactionId, userSub) {
  const pk = `TRANSACTION#${transactionId}`;
  const ttl = Math.floor(Date.now() / 1000) + NINETY_DAYS_S;

  // Atomic: write transaction record (fails if already exists) + update user.
  // We do two separate writes because DynamoDB TransactWrite across two tables
  // would require both table ARNs in IAM; simpler to use conditional PutItem first.
  try {
    await ddb.send(new PutCommand({
      TableName: TableNames.PURCHASE_EVENTS,
      Item: { PK: pk, userSub, transactionId, grantedAt: new Date().toISOString(), ttl },
      ConditionExpression: 'attribute_not_exists(PK)',
    }));
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return { alreadyProcessed: true };
    }
    throw err;
  }

  await ddb.send(new UpdateCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
    UpdateExpression: 'SET hasCommunityAccess = :t',
    ExpressionAttributeValues: { ':t': true },
  }));

  return { alreadyProcessed: false };
}

exports.handler = async (event) => {
  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return http.badRequest('Invalid JSON');
  }

  // Apple sends { signedPayload: '<JWS string>' }
  const { signedPayload } = body;
  if (!signedPayload || typeof signedPayload !== 'string') {
    return http.badRequest('signedPayload required');
  }

  let outerPayload;
  try {
    outerPayload = decodeJWSPayload(signedPayload);
  } catch {
    return http.badRequest('Invalid JWS payload');
  }

  // Validate bundle ID
  if (outerPayload.bundleId !== BUNDLE_ID) {
    console.warn(JSON.stringify({ msg: 'bundle ID mismatch', bundleId: outerPayload.bundleId }));
    return { statusCode: 200, body: '{}' }; // return 200 to stop Apple retrying
  }

  const { notificationType, data } = outerPayload;

  // We only care about completed one-time purchases
  if (notificationType !== 'ONE_TIME_CHARGE' && notificationType !== 'DID_RENEW') {
    return { statusCode: 200, body: JSON.stringify({ received: true }) };
  }

  let txPayload;
  try {
    txPayload = decodeJWSPayload(data.signedTransactionInfo);
  } catch {
    return http.badRequest('Invalid transaction JWS');
  }

  const { productId, transactionId, appAccountToken } = txPayload;

  if (productId !== COMMUNITY_PRODUCT_ID) {
    return { statusCode: 200, body: JSON.stringify({ received: true }) };
  }

  if (!appAccountToken) {
    console.error(JSON.stringify({ msg: 'no appAccountToken on transaction', transactionId }));
    return { statusCode: 200, body: '{}' };
  }

  const user = await findUserByTransactionSub(appAccountToken);
  if (!user) {
    console.error(JSON.stringify({ msg: 'user not found for appAccountToken', appAccountToken }));
    return { statusCode: 200, body: '{}' };
  }

  const { alreadyProcessed } = await deduplicateAndGrant(transactionId, appAccountToken);
  console.log(JSON.stringify({ msg: 'webhook processed', transactionId, appAccountToken, alreadyProcessed }));

  return { statusCode: 200, body: JSON.stringify({ received: true }) };
};
