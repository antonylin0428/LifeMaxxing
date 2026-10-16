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

  const communityId = event.pathParameters?.communityId;
  if (!communityId) return http.badRequest('communityId path parameter required');

  // Verify user is a member
  const { Item: membership } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: `MEMBER#${userSub}` },
  }));
  if (!membership) return http.forbidden('You are not a member of this community');

  // Posts are keyed by the poster's own local calendar day (see
  // postCommunityPhoto), which can run up to ~1 day ahead/behind UTC
  // depending on timezone. Query a UTC-anchored net wide enough to catch
  // any post that could still be within the last 24 real hours, then filter
  // precisely below using the absolute postedAt timestamp - that's what
  // actually defines "taken down after 24 hours," not the calendar date.
  const netStart = todayString('UTC', new Date(Date.now() - 2 * 24 * 60 * 60 * 1000));
  const netEnd = todayString('UTC', new Date(Date.now() + 24 * 60 * 60 * 1000));

  const { Items: candidates = [] } = await ddb.send(new QueryCommand({
    TableName: COMMUNITY_FEED_TABLE,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
    ExpressionAttributeValues: {
      ':pk': `COMMUNITY#${communityId}`,
      ':start': `DATE#${netStart}#USER#`,
      ':end': `DATE#${netEnd}#USER#~`,
    },
  }));

  const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  const posts = candidates.filter(p => new Date(p.postedAt).getTime() >= cutoff);

  if (posts.length === 0) return http.ok([]);

  // BatchGet user profiles for enrichment
  const uniqueSubs = [...new Set(posts.map(p => p.userSub))];
  const profileKeys = uniqueSubs.map(sub => ({ PK: `USER#${sub}`, SK: 'PROFILE' }));

  const profileRes = await ddb.send(new BatchGetCommand({
    RequestItems: {
      [TableNames.USERS]: {
        Keys: profileKeys,
        ProjectionExpression: 'PK, username, #r',
        ExpressionAttributeNames: { '#r': 'rank' },
      },
    },
  }));

  const userMap = {};
  for (const u of (profileRes.Responses?.[TableNames.USERS] || [])) {
    userMap[u.PK] = u;
  }

  // Generate presigned GET URLs and build response
  const enriched = await Promise.all(posts.map(async (post) => {
    const cmd = new GetObjectCommand({ Bucket: BUCKET, Key: post.photoS3Key });
    const photoUrl = await getSignedUrl(s3, cmd, { expiresIn: 3600 });
    const u = userMap[`USER#${post.userSub}`] || {};
    return {
      userSub: post.userSub,
      username: u.username || 'Unknown',
      rank: u.rank || '',
      photoUrl,
      postedAt: post.postedAt,
      isMe: post.userSub === userSub,
    };
  }));

  // Sort newest first
  enriched.sort((a, b) => b.postedAt.localeCompare(a.postedAt));

  return http.ok(enriched);
};
