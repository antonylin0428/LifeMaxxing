'use strict';

const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;
const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  try { getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const targetSub = event.pathParameters?.userSub;
  if (!targetSub) return http.badRequest('userSub path parameter required');

  const [profileRes, logsRes] = await Promise.all([
    ddb.send(new GetCommand({
      TableName: TableNames.USERS,
      Key: { PK: `USER#${targetSub}`, SK: 'PROFILE' },
    })),
    ddb.send(new QueryCommand({
      TableName: TableNames.DAILY_LOGS,
      KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
      FilterExpression: 'attribute_exists(photoS3Key)',
      ExpressionAttributeValues: {
        ':pk': `USER#${targetSub}`,
        ':start': 'LOG#2020-01-01#FITNESS',
        ':end': 'LOG#9999-99-99#FITNESS~',
      },
      ScanIndexForward: false,
      Limit: 1,
    })),
  ]);

  const profile = profileRes.Item;
  if (!profile) return http.notFound('User not found');

  const recentLog = logsRes.Items?.[0];

  const [avatarUrl, recentGymPhotoUrl] = await Promise.all([
    profile.avatarKey
      ? getSignedUrl(s3, new GetObjectCommand({ Bucket: BUCKET, Key: profile.avatarKey }), { expiresIn: 3600 })
      : Promise.resolve(null),
    recentLog?.photoS3Key
      ? getSignedUrl(s3, new GetObjectCommand({ Bucket: BUCKET, Key: recentLog.photoS3Key }), { expiresIn: 3600 })
      : Promise.resolve(null),
  ]);

  return http.ok({
    sub: targetSub,
    username: profile.username,
    rank: profile.rank || 'LOW_TIER_NORMIE_1',
    totalXP: profile.totalXP || 0,
    achievements: profile.achievements ? [...profile.achievements] : [],
    ...(avatarUrl ? { avatarUrl } : {}),
    ...(recentGymPhotoUrl ? { recentGymPhotoUrl, recentGymPhotoDate: recentLog.SK.split('#')[1] } : {}),
  });
};
