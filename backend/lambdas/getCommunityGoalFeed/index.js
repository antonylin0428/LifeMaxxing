'use strict';

const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { GetCommand, QueryCommand, BatchGetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, todayString, http, dynamo } = require('lifemaxxing-shared');

const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;
const { ddb, TableNames } = dynamo;
const COMMUNITY_FEED_TABLE = process.env.COMMUNITY_FEED_TABLE;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const { communityId, goalId } = event.pathParameters ?? {};
  if (!communityId || !goalId) return http.badRequest('communityId and goalId path parameters required');

  const { Item: membership } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: `MEMBER#${userSub}` },
  }));
  if (!membership) return http.forbidden('Not a member of this community');

  const date = todayString();

  const completionsRes = await ddb.send(new QueryCommand({
    TableName: COMMUNITY_FEED_TABLE,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
    ExpressionAttributeValues: {
      ':pk': `COMMUNITY#${communityId}`,
      ':start': `DATE#${date}#GOAL#${goalId}#USER#`,
      ':end': `DATE#${date}#GOAL#${goalId}#USER#~`,
    },
  }));

  const items = completionsRes.Items ?? [];
  if (items.length === 0) return http.ok([]);

  // BatchGet user profiles
  const uniqueSubs = [...new Set(items.map(i => i.userSub))];
  const profileRes = await ddb.send(new BatchGetCommand({
    RequestItems: {
      [TableNames.USERS]: {
        Keys: uniqueSubs.map(sub => ({ PK: `USER#${sub}`, SK: 'PROFILE' })),
        ProjectionExpression: 'PK, username, #r, avatarKey',
        ExpressionAttributeNames: { '#r': 'rank' },
      },
    },
  }));

  const profileMap = {};
  for (const u of (profileRes.Responses?.[TableNames.USERS] ?? [])) {
    profileMap[u.PK] = u;
  }

  // Generate presigned URLs
  const enriched = await Promise.all(items.map(async item => {
    const profile = profileMap[`USER#${item.userSub}`] ?? {};

    let photoUrl = null;
    if (item.photoS3Key) {
      photoUrl = await getSignedUrl(s3, new GetObjectCommand({ Bucket: BUCKET, Key: item.photoS3Key }), { expiresIn: 3600 });
    }

    let avatarUrl = null;
    if (profile.avatarKey) {
      avatarUrl = await getSignedUrl(s3, new GetObjectCommand({ Bucket: BUCKET, Key: profile.avatarKey }), { expiresIn: 3600 });
    }

    return {
      userSub: item.userSub,
      username: profile.username ?? 'Unknown',
      rank: profile.rank ?? '',
      avatarUrl,
      text: item.text ?? null,
      photoUrl,
      completedAt: item.completedAt,
      isMe: item.userSub === userSub,
    };
  }));

  enriched.sort((a, b) => {
    if (a.isMe) return -1;
    if (b.isMe) return 1;
    return b.completedAt.localeCompare(a.completedAt);
  });

  return http.ok(enriched);
};
