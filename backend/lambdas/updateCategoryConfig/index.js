'use strict';

const { UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, isValidCategory, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

// Enable/disable an optional category (Reflection, Spiritual Journey).
// Does NOT touch XP/streak/rank fields - those are off-limits to every
// route except completeTask's internal transaction.
exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const categoryId = event.pathParameters?.categoryId;
  if (!categoryId || !isValidCategory(categoryId)) {
    return http.badRequest('Unknown categoryId');
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return http.badRequest('Request body must be valid JSON');
  }
  if (typeof body.enabled !== 'boolean') {
    return http.badRequest('enabled (boolean) is required');
  }

  await ddb.send(new UpdateCommand({
    TableName: TableNames.CATEGORY_STATS,
    Key: { PK: `USER#${userSub}`, SK: `CATEGORY#${categoryId}` },
    UpdateExpression: 'SET enabled = :enabled, currentStreak = if_not_exists(currentStreak, :zero), longestStreak = if_not_exists(longestStreak, :zero), categoryXPToday = if_not_exists(categoryXPToday, :zero), freezesAvailable = if_not_exists(freezesAvailable, :one)',
    ExpressionAttributeValues: {
      ':enabled': body.enabled,
      ':zero': 0,
      ':one': 1,
    },
  }));

  return http.ok({ categoryId, enabled: body.enabled });
};
