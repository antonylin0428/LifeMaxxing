'use strict';

const { QueryCommand, BatchGetCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

// MVP: friends leaderboard sorted by lifetime XP. Derived live from
// Friendships + Users - no denormalized leaderboard table to keep in sync.
// When seasons launch, this gains a season-mode branch that sorts by
// seasonXP instead (see Users.GSI2 in the schema design).
exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const [friendshipsRes, meRes] = await Promise.all([
    ddb.send(new QueryCommand({
      TableName: TableNames.FRIENDSHIPS,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :skPrefix)',
      ExpressionAttributeValues: { ':pk': `USER#${userSub}`, ':skPrefix': 'FRIEND#' },
    })),
    ddb.send(new GetCommand({ TableName: TableNames.USERS, Key: { PK: `USER#${userSub}`, SK: 'PROFILE' } })),
  ]);

  const friendSubs = (friendshipsRes.Items || []).map((f) => f.friendSub);

  let friendProfiles = [];
  if (friendSubs.length > 0) {
    const { Responses } = await ddb.send(new BatchGetCommand({
      RequestItems: {
        [TableNames.USERS]: {
          Keys: friendSubs.map((sub) => ({ PK: `USER#${sub}`, SK: 'PROFILE' })),
        },
      },
    }));
    friendProfiles = Responses?.[TableNames.USERS] || [];
  }

  const entries = [...friendProfiles, meRes.Item].filter(Boolean).map((u) => ({
    sub: u.PK.replace('USER#', ''),
    username: u.username,
    totalXP: u.totalXP,
    rank: u.rank,
    isMe: u.PK === `USER#${userSub}`,
  }));

  entries.sort((a, b) => b.totalXP - a.totalXP);

  return http.ok({ leaderboard: entries });
};
