'use strict';

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { GetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, todayString, http, dynamo } = require('lifemaxxing-shared');

const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;
const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const { communityId, goalId } = event.pathParameters ?? {};
  if (!communityId || !goalId) return http.badRequest('communityId and goalId path parameters required');

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
  if (!goal) return http.notFound('Goal not found');
  if (goal.trackingType === 'text') return http.badRequest('This goal does not require a photo');

  const date = todayString();
  const s3Key = `community-feed/${communityId}/${goalId}/${date}/${userSub}.jpg`;
  const command = new PutObjectCommand({ Bucket: BUCKET, Key: s3Key, ContentType: 'image/jpeg' });
  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

  return http.ok({ uploadUrl, s3Key });
};
