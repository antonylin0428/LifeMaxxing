'use strict';

const { QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;
const USERNAME_RE = /^[a-zA-Z0-9_]{3,20}$/;

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
    return http.badRequest('Invalid JSON');
  }

  const { username, avatarKey } = body;
  if (username === undefined && avatarKey === undefined) {
    return http.badRequest('Provide at least one of: username, avatarKey');
  }

  const setExprs = ['#ua = :ua'];
  const names = { '#ua': 'updatedAt' };
  const vals = { ':ua': new Date().toISOString() };

  if (username !== undefined) {
    if (!USERNAME_RE.test(username)) {
      return http.badRequest('Username must be 3–20 characters: letters, numbers, underscores only');
    }
    const { Items } = await ddb.send(new QueryCommand({
      TableName: TableNames.USERS,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :gsi1pk',
      ExpressionAttributeValues: { ':gsi1pk': `USERNAME#${username}` },
    }));
    const owner = (Items || [])[0];
    if (owner && owner.PK !== `USER#${userSub}`) {
      return http.conflict('Username is already taken');
    }
    setExprs.push('#un = :un', 'GSI1PK = :gsi1pk', 'GSI1SK = :gsi1sk');
    names['#un'] = 'username';
    vals[':un'] = username;
    vals[':gsi1pk'] = `USERNAME#${username}`;
    vals[':gsi1sk'] = 'PROFILE';
  }

  if (avatarKey !== undefined) {
    setExprs.push('avatarKey = :avatarKey');
    vals[':avatarKey'] = avatarKey;
  }

  await ddb.send(new UpdateCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
    UpdateExpression: `SET ${setExprs.join(', ')}`,
    ExpressionAttributeNames: names,
    ExpressionAttributeValues: vals,
  }));

  return http.ok({ updated: true });
};
