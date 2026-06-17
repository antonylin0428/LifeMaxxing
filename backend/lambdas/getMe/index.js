'use strict';

const { GetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const { Item } = await ddb.send(new GetCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
  }));

  if (!Item) return http.notFound('User profile not found');

  const { PK, SK, ...profile } = Item;
  return http.ok(profile);
};
