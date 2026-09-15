'use strict';

const { GetCommand, QueryCommand, BatchGetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const communityId = event.pathParameters?.communityId;
  if (!communityId) return http.badRequest('communityId path parameter required');

  // Verify community exists
  const { Item: community } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: 'PROFILE' },
  }));
  if (!community) return http.notFound('Community not found');

  // Query all members
  const membersRes = await ddb.send(new QueryCommand({
    TableName: TableNames.COMMUNITIES,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :skPrefix)',
    ExpressionAttributeValues: {
      ':pk': `COMMUNITY#${communityId}`,
      ':skPrefix': 'MEMBER#',
    },
  }));

  const members = membersRes.Items || [];
  if (members.length === 0) return http.ok({ communityId, leaderboard: [] });

  const memberSubs = members.map((m) => m.userSub);

  // BatchGetItem user profiles
  const { Responses } = await ddb.send(new BatchGetCommand({
    RequestItems: {
      [TableNames.USERS]: {
        Keys: memberSubs.map((sub) => ({ PK: `USER#${sub}`, SK: 'PROFILE' })),
      },
    },
  }));

  const entries = (Responses?.[TableNames.USERS] || [])
    .map((u) => ({
      sub: u.PK.replace('USER#', ''),
      username: u.username,
      totalXP: u.totalXP || 0,
      rank: u.rank,
      isMe: u.PK === `USER#${userSub}`,
    }))
    .sort((a, b) => b.totalXP - a.totalXP);

  return http.ok({ communityId, name: community.name, leaderboard: entries });
};
