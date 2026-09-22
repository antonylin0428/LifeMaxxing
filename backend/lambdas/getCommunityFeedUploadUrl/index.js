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

  const communityId = event.pathParameters?.communityId;
  if (!communityId) return http.badRequest('communityId path parameter required');

  // Verify user is a member
  const { Item: membership } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: `MEMBER#${userSub}` },
  }));
  if (!membership) return http.forbidden('You are not a member of this community');

  const date = todayString();
  // Deterministic key: retaking on the same day overwrites the same S3 object
  const s3Key = `community-feed/${communityId}/${date}/${userSub}.jpg`;
  const command = new PutObjectCommand({ Bucket: BUCKET, Key: s3Key, ContentType: 'image/jpeg' });
  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

  return http.ok({ uploadUrl, s3Key });
};
