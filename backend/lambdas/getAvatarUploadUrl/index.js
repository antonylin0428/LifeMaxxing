'use strict';

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { randomUUID } = require('node:crypto');
const { getUserSub, http } = require('lifemaxxing-shared');

const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const s3Key = `avatars/${userSub}/${randomUUID()}.jpg`;
  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: s3Key,
    ContentType: 'image/jpeg',
  });
  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
  return http.ok({ uploadUrl, s3Key });
};
