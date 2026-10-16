'use strict';

const { QueryCommand, BatchGetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const { Items } = await ddb.send(new QueryCommand({
    TableName: TableNames.FRIENDSHIPS,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :skPrefix)',
    ExpressionAttributeValues: { ':pk': `USER#${userSub}`, ':skPrefix': 'FRIEND#' },
  }));

  const friendItems = Items || [];
  const friendSubs = friendItems.map((f) => f.friendSub);

  // Always read usernames live from the Users table so renames propagate
  // immediately. The cached friendUsername in Friendships is stale after any
  // updateProfile call and cannot be trusted.
  let liveProfiles = {};
  if (friendSubs.length > 0) {
    const { Responses } = await ddb.send(new BatchGetCommand({
      RequestItems: {
        [TableNames.USERS]: {
          Keys: friendSubs.map((sub) => ({ PK: `USER#${sub}`, SK: 'PROFILE' })),
          ProjectionExpression: 'PK, username, avatarKey',
        },
      },
    }));
    (Responses?.[TableNames.USERS] || []).forEach((u) => {
      liveProfiles[u.PK.replace('USER#', '')] = u;
    });
  }

  const friends = friendItems.map(({ friendSub, becameFriendsAt }) => ({
    friendSub,
    friendUsername: liveProfiles[friendSub]?.username ?? friendSub,
    becameFriendsAt,
  }));

  return http.ok({ friends });
};
