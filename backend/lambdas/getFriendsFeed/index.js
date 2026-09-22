'use strict';

const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { QueryCommand, BatchGetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, todayString, http, dynamo } = require('lifemaxxing-shared');

const s3 = new S3Client({});
const BUCKET = process.env.PHOTOS_BUCKET;
const { ddb, TableNames } = dynamo;

// Returns ISO date string N days before today (UTC)
function daysAgo(n) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - n);
  return d.toISOString().slice(0, 10);
}

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  // 1. Get the user's friends
  const friendshipsRes = await ddb.send(new QueryCommand({
    TableName: TableNames.FRIENDSHIPS,
    KeyConditionExpression: 'PK = :pk',
    ExpressionAttributeValues: { ':pk': `USER#${userSub}` },
  }));

  const friendSubs = (friendshipsRes.Items || []).map(item => item.SK.replace('FRIEND#', ''));
  // Always include the current user's own posts in the feed.
  const allSubs = [...new Set([userSub, ...friendSubs])];

  // 2. Query DailyLogs for each person's FITNESS entries in the last 7 days
  const rangeStart = daysAgo(7);
  const today = todayString();

  const logQueries = allSubs.map(sub =>
    ddb.send(new QueryCommand({
      TableName: TableNames.DAILY_LOGS,
      KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
      FilterExpression: 'attribute_exists(photoS3Key)',
      ExpressionAttributeValues: {
        ':pk': `USER#${sub}`,
        ':start': `LOG#${rangeStart}#FITNESS`,
        ':end': `LOG#${today}#FITNESS~`,
      },
    })).then(res => ({ sub, items: res.Items || [] }))
  );

  const logResults = await Promise.all(logQueries);
  const posts = logResults.flatMap(({ sub, items }) =>
    items.map(item => ({ sub, item }))
  );

  if (posts.length === 0) {
    return http.ok([]);
  }

  // 3. BatchGet usernames + FITNESS streak for everyone who has posts
  const uniqueSubs = [...new Set(posts.map(p => p.sub))];
  const profileKeys = uniqueSubs.map(sub => ({ PK: `USER#${sub}`, SK: 'PROFILE' }));
  const streakKeys = uniqueSubs.map(sub => ({ PK: `USER#${sub}`, SK: 'CATEGORY#FITNESS' }));

  const [profileRes, streakRes] = await Promise.all([
    ddb.send(new BatchGetCommand({
      RequestItems: {
        [TableNames.USERS]: {
          Keys: profileKeys,
          ProjectionExpression: 'PK, username, #r',
          ExpressionAttributeNames: { '#r': 'rank' },
        },
      },
    })),
    ddb.send(new BatchGetCommand({
      RequestItems: {
        [TableNames.CATEGORY_STATS]: {
          Keys: streakKeys,
          ProjectionExpression: 'PK, currentStreak',
        },
      },
    })),
  ]);

  const userMap = {};
  for (const u of (profileRes.Responses?.[TableNames.USERS] || [])) {
    userMap[u.PK] = u;
  }
  const streakMap = {};
  for (const s of (streakRes.Responses?.[TableNames.CATEGORY_STATS] || [])) {
    streakMap[s.PK] = s.currentStreak || 0;
  }

  // 4. Generate pre-signed GET URLs (1 hour) and build response
  const enriched = await Promise.all(posts.map(async ({ sub, item }) => {
    const command = new GetObjectCommand({ Bucket: BUCKET, Key: item.photoS3Key });
    const photoUrl = await getSignedUrl(s3, command, { expiresIn: 3600 });
    const u = userMap[`USER#${sub}`] || {};
    return {
      s3Key: item.photoS3Key,
      username: u.username || 'Unknown',
      rank: u.rank || '',
      currentStreak: streakMap[`USER#${sub}`] || 0,
      xpAwarded: item.xpAwarded,
      completedAt: item.completedAtServerTime,
      photoUrl,
    };
  }));

  // Sort newest first
  enriched.sort((a, b) => b.completedAt.localeCompare(a.completedAt));

  return http.ok(enriched);
};
