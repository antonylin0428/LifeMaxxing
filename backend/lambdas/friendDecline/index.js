'use strict';

const { DeleteCommand } = require('@aws-sdk/lib-dynamodb');
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

  await ddb.send(new DeleteCommand({
    TableName: TableNames.FRIEND_REQUESTS,
    Key: { PK: `USER#${userSub}`, SK: `REQUEST#${requesterSub}` },
  }));

  return http.ok({ requesterSub, status: 'DECLINED' });
};
