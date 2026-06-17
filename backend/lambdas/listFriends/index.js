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

  const { Items } = await ddb.send(new QueryCommand({
    TableName: TableNames.FRIENDSHIPS,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :skPrefix)',
    ExpressionAttributeValues: { ':pk': `USER#${userSub}`, ':skPrefix': 'FRIEND#' },
  }));

  const friends = (Items || []).map(({ friendSub, friendUsername, becameFriendsAt }) => ({
    friendSub, friendUsername, becameFriendsAt,
  }));

  return http.ok({ friends });
};
