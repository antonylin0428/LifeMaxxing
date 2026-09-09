'use strict';

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { randomUUID } = require('node:crypto');
const { getUserSub, todayString, http } = require('lifemaxxing-shared');

const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const date = todayString();
  const s3Key = `gym-photos/${userSub}/${date}/${randomUUID()}.jpg`;

  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: s3Key,
    ContentType: 'image/jpeg',
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 }); // 5 min

  return http.ok({ uploadUrl, s3Key });
};
