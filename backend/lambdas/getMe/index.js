'use strict';

const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { GetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;
const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;

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

  const { PK, SK, achievements: rawAchievements, avatarKey, ...profile } = Item;

  let avatarUrl;
  if (avatarKey) {
    const cmd = new GetObjectCommand({ Bucket: BUCKET, Key: avatarKey });
    avatarUrl = await getSignedUrl(s3, cmd, { expiresIn: 3600 });
  }

  return http.ok({
    ...profile,
    achievements: rawAchievements ? [...rawAchievements] : [],
    hasCommunityAccess: profile.hasCommunityAccess ?? false,
    ...(avatarUrl !== undefined ? { avatarUrl } : {}),
  });
};
