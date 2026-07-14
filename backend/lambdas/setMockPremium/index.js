'use strict';

// TESTING-ONLY: lets a signed-in user flip their own mock premium flag with
// no payment behind it. This stands in for a real entitlement source (App
// Store Server Notifications / RevenueCat / Stripe webhook) - when real
// payments are added, this route should be removed and isPremium should
// only ever be set by that webhook, never by the client.

const { UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

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
  if (typeof body.isPremium !== 'boolean') {
    return http.badRequest('isPremium (boolean) is required');
  }

  await ddb.send(new UpdateCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
    UpdateExpression: 'SET isPremium = :isPremium',
    ExpressionAttributeValues: { ':isPremium': body.isPremium },
  }));

  return http.ok({ isPremium: body.isPremium });
};
