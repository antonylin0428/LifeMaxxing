'use strict';

const { QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  // Inbox: requests addressed to me.
  const { Items: inbox } = await ddb.send(new QueryCommand({
    TableName: TableNames.FRIEND_REQUESTS,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :skPrefix)',
    ExpressionAttributeValues: { ':pk': `USER#${userSub}`, ':skPrefix': 'REQUEST#' },
  }));

  // Sent: requests I sent, via GSI1.
  const { Items: sent } = await ddb.send(new QueryCommand({
    TableName: TableNames.FRIEND_REQUESTS,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :gsi1pk',
    ExpressionAttributeValues: { ':gsi1pk': `USER#${userSub}` },
  }));

  return http.ok({
    received: (inbox || []).map(({ requesterSub, requesterUsername, createdAt }) => ({ requesterSub, requesterUsername, createdAt })),
    sent: (sent || []).map(({ GSI1SK, createdAt }) => ({ recipientSub: GSI1SK.replace('REQUEST#', ''), createdAt })),
  });
};
