'use strict';

const { QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  try {
    getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const username = event.queryStringParameters?.username;
  if (!username) return http.badRequest('username query parameter is required');

  const { Items } = await ddb.send(new QueryCommand({
    TableName: TableNames.USERS,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :gsi1pk',
    ExpressionAttributeValues: { ':gsi1pk': `USERNAME#${username}` },
  }));

  const match = (Items || [])[0];
  if (!match) return http.notFound('No user with that username');

  return http.ok({ username: match.username, sub: match.PK.replace('USER#', ''), rank: match.rank });
};
