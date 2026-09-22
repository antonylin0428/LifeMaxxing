'use strict';

const { GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, todayString, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;
const COMMUNITY_FEED_TABLE = process.env.COMMUNITY_FEED_TABLE;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const communityId = event.pathParameters?.communityId;
  if (!communityId) return http.badRequest('communityId path parameter required');

  let body;
  try { body = JSON.parse(event.body || '{}'); } catch { return http.badRequest('Invalid JSON'); }

  const { photoS3Key } = body;
  if (!photoS3Key) return http.badRequest('photoS3Key is required');

  // Verify user is a member
  const { Item: membership } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: `MEMBER#${userSub}` },
  }));
  if (!membership) return http.forbidden('You are not a member of this community');

  const date = todayString();
  // TTL: 30 days from now (auto-purge old feed posts)
  const ttl = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;

  // PutItem replaces any existing entry for this user today (retake semantics)
  await ddb.send(new PutCommand({
    TableName: COMMUNITY_FEED_TABLE,
    Item: {
      PK: `COMMUNITY#${communityId}`,
      SK: `DATE#${date}#USER#${userSub}`,
      communityId,
      userSub,
      date,
      photoS3Key,
      postedAt: new Date().toISOString(),
      ttl,
    },
  }));

  return http.ok({ posted: true });
};
