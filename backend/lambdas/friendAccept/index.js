'use strict';

const { GetCommand, TransactWriteCommand } = require('@aws-sdk/lib-dynamodb');
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
  const { requesterSub } = body;
  if (!requesterSub) return http.badRequest('requesterSub is required');

  const [requestRes, meRes, themRes] = await Promise.all([
    ddb.send(new GetCommand({
      TableName: TableNames.FRIEND_REQUESTS,
      Key: { PK: `USER#${userSub}`, SK: `REQUEST#${requesterSub}` },
    })),
    ddb.send(new GetCommand({ TableName: TableNames.USERS, Key: { PK: `USER#${userSub}`, SK: 'PROFILE' } })),
    ddb.send(new GetCommand({ TableName: TableNames.USERS, Key: { PK: `USER#${requesterSub}`, SK: 'PROFILE' } })),
  ]);

  if (!requestRes.Item) return http.notFound('No pending request from this user');
  if (!meRes.Item || !themRes.Item) return http.notFound('User profile not found');

  const nowIso = new Date().toISOString();
  await ddb.send(new TransactWriteCommand({
    TransactItems: [
      {
        Delete: {
          TableName: TableNames.FRIEND_REQUESTS,
          Key: { PK: `USER#${userSub}`, SK: `REQUEST#${requesterSub}` },
        },
      },
      {
        Put: {
          TableName: TableNames.FRIENDSHIPS,
          Item: {
            PK: `USER#${userSub}`,
            SK: `FRIEND#${requesterSub}`,
            friendSub: requesterSub,
            friendUsername: themRes.Item.username,
            becameFriendsAt: nowIso,
          },
        },
      },
      {
        Put: {
          TableName: TableNames.FRIENDSHIPS,
          Item: {
            PK: `USER#${requesterSub}`,
            SK: `FRIEND#${userSub}`,
            friendSub: userSub,
            friendUsername: meRes.Item.username,
            becameFriendsAt: nowIso,
          },
        },
      },
    ],
  }));

  return http.ok({ friendSub: requesterSub, status: 'ACCEPTED' });
};
