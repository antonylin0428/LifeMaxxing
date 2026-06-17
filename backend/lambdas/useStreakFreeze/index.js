'use strict';

const { GetCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, isValidCategory, todayString, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

// Protects a category streak for one missed day. Awards 0 XP - this route
// can never grant XP, only preserve currentStreak/lastCompletedDate.
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
  const { categoryId } = body;
  if (!categoryId || !isValidCategory(categoryId)) {
    return http.badRequest('categoryId is required and must be a known category');
  }

  const key = { PK: `USER#${userSub}`, SK: `CATEGORY#${categoryId}` };
  const { Item: stats } = await ddb.send(new GetCommand({ TableName: TableNames.CATEGORY_STATS, Key: key }));
  if (!stats) return http.notFound('Category not set up yet');
  if (!stats.freezesAvailable || stats.freezesAvailable <= 0) {
    return http.conflict('No streak freezes available');
  }

  const serverDate = todayString();
  await ddb.send(new UpdateCommand({
    TableName: TableNames.CATEGORY_STATS,
    Key: key,
    UpdateExpression: 'SET lastCompletedDate = :today, freezesAvailable = freezesAvailable - :one, freezesUsedThisWeek = freezesUsedThisWeek + :one',
    ConditionExpression: 'freezesAvailable > :zero',
    ExpressionAttributeValues: { ':today': serverDate, ':one': 1, ':zero': 0 },
  }));

  return http.ok({ categoryId, frozenForDate: serverDate, streakPreserved: stats.currentStreak });
};
