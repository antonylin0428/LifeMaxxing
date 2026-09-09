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
  if (friendSubs.length === 0) {
    return http.ok([]);
  }

  // 2. Query DailyLogs for each friend's FITNESS entries in the last 7 days
  const rangeStart = daysAgo(7);
  const today = todayString();

  const logQueries = friendSubs.map(sub =>
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

  // 3. BatchGet usernames for friends who have posts
  const uniqueSubs = [...new Set(posts.map(p => p.sub))];
  const batchKeys = uniqueSubs.map(sub => ({ PK: `USER#${sub}`, SK: 'PROFILE' }));

  const batchRes = await ddb.send(new BatchGetCommand({
    RequestItems: {
      [TableNames.USERS]: { Keys: batchKeys, ProjectionExpression: 'PK, username, #r, currentStreak',
        ExpressionAttributeNames: { '#r': 'rank' } },
    },
  }));

  const userMap = {};
  for (const u of (batchRes.Responses?.[TableNames.USERS] || [])) {
    userMap[u.PK] = u;
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
      currentStreak: u.currentStreak || 0,
      xpAwarded: item.xpAwarded,
      completedAt: item.completedAtServerTime,
      photoUrl,
    };
  }));

  // Sort newest first
  enriched.sort((a, b) => b.completedAt.localeCompare(a.completedAt));

  return http.ok(enriched);
};
