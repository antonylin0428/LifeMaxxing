'use strict';

const { QueryCommand, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

const MAX_PENDING_OUTGOING_REQUESTS = 50;

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
  const { recipientSub } = body;
  if (!recipientSub || typeof recipientSub !== 'string') {
    return http.badRequest('recipientSub is required');
  }
  if (recipientSub === userSub) {
    return http.badRequest('Cannot friend yourself');
  }

  // Anti-spam: cap outstanding outgoing requests via GSI1 (requesterSub).
  const { Items: outgoing } = await ddb.send(new QueryCommand({
    TableName: TableNames.FRIEND_REQUESTS,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :gsi1pk',
    ExpressionAttributeValues: { ':gsi1pk': `USER#${userSub}` },
  }));
  if ((outgoing || []).length >= MAX_PENDING_OUTGOING_REQUESTS) {
    return http.conflict('Too many pending outgoing friend requests');
  }

  const requester = await ddb.send(new GetCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
  }));
  if (!requester.Item) return http.notFound('Requester profile not found');

  const nowIso = new Date().toISOString();
  try {
    await ddb.send(new PutCommand({
      TableName: TableNames.FRIEND_REQUESTS,
      Item: {
        PK: `USER#${recipientSub}`,
        SK: `REQUEST#${userSub}`,
        GSI1PK: `USER#${userSub}`,
        GSI1SK: `REQUEST#${recipientSub}`,
        requesterSub: userSub,
        requesterUsername: requester.Item.username,
        status: 'PENDING',
        createdAt: nowIso,
      },
      ConditionExpression: 'attribute_not_exists(PK)',
    }));
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return http.conflict('A request to this user is already pending');
    }
    throw err;
  }

  return http.ok({ recipientSub, status: 'PENDING' });
};
