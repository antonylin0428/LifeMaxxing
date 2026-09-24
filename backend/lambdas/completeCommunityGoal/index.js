'use strict';

const { GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, todayString, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;
const COMMUNITY_FEED_TABLE = process.env.COMMUNITY_FEED_TABLE;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const { communityId, goalId } = event.pathParameters ?? {};
  if (!communityId || !goalId) return http.badRequest('communityId and goalId path parameters required');

  let body;
  try { body = JSON.parse(event.body || '{}'); } catch { return http.badRequest('Invalid JSON'); }

  const [{ Item: membership }, { Item: goal }] = await Promise.all([
    ddb.send(new GetCommand({
      TableName: TableNames.COMMUNITIES,
      Key: { PK: `COMMUNITY#${communityId}`, SK: `MEMBER#${userSub}` },
    })),
    ddb.send(new GetCommand({
      TableName: TableNames.COMMUNITIES,
      Key: { PK: `COMMUNITY#${communityId}`, SK: `GOAL#${goalId}` },
    })),
  ]);

  if (!membership) return http.forbidden('Not a member of this community');
  if (!goal || goal.isActive === false) return http.notFound('Goal not found');

  const { photoS3Key, text } = body;

  if ((goal.trackingType === 'photo' || goal.trackingType === 'both') && !photoS3Key) {
    return http.badRequest('photoS3Key is required for this goal');
  }
  if ((goal.trackingType === 'text' || goal.trackingType === 'both') && (!text || !text.trim())) {
    return http.badRequest('text is required for this goal');
  }
  if (text && text.length > 500) {
    return http.badRequest('text must be 500 characters or fewer');
  }

  const date = todayString();
  const ttl = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;

  await ddb.send(new PutCommand({
    TableName: COMMUNITY_FEED_TABLE,
    Item: {
      PK: `COMMUNITY#${communityId}`,
      SK: `DATE#${date}#GOAL#${goalId}#USER#${userSub}`,
      communityId,
      goalId,
      userSub,
      date,
      ...(photoS3Key ? { photoS3Key } : {}),
      ...(text?.trim() ? { text: text.trim() } : {}),
      completedAt: new Date().toISOString(),
      ttl,
    },
  }));

  return http.ok({ completed: true });
};
