'use strict';

const { GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, todayString, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;
const COMMUNITY_FEED_TABLE = process.env.COMMUNITY_FEED_TABLE;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const communityId = event.pathParameters?.communityId;
  if (!communityId) return http.badRequest('communityId path parameter required');

  const { Item: membership } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: `MEMBER#${userSub}` },
  }));
  if (!membership) return http.forbidden('Not a member of this community');

  const date = todayString();

  const [goalsRes, completionsRes] = await Promise.all([
    ddb.send(new QueryCommand({
      TableName: TableNames.COMMUNITIES,
      KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
      ExpressionAttributeValues: {
        ':pk': `COMMUNITY#${communityId}`,
        ':start': 'GOAL#',
        ':end': 'GOAL#~',
      },
    })),
    ddb.send(new QueryCommand({
      TableName: COMMUNITY_FEED_TABLE,
      KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
      FilterExpression: 'userSub = :sub',
      ExpressionAttributeValues: {
        ':pk': `COMMUNITY#${communityId}`,
        ':start': `DATE#${date}#GOAL#`,
        ':end': `DATE#${date}#GOAL#~`,
        ':sub': userSub,
      },
    })),
  ]);

  // Build completion map: goalId -> completion item
  const completionMap = {};
  for (const item of (completionsRes.Items || [])) {
    // SK: DATE#<date>#GOAL#<goalId>#USER#<sub>
    const goalId = item.SK.split('#')[3];
    completionMap[goalId] = item;
  }

  const goals = (goalsRes.Items || [])
    .filter(g => g.isActive !== false)
    .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
    .map(g => ({
      goalId: g.goalId,
      name: g.name,
      description: g.description ?? null,
      emoji: g.emoji ?? '⭐',
      trackingType: g.trackingType,
      order: g.order ?? 0,
      myCompletion: completionMap[g.goalId]
        ? {
            text: completionMap[g.goalId].text ?? null,
            hasPhoto: !!completionMap[g.goalId].photoS3Key,
            completedAt: completionMap[g.goalId].completedAt,
          }
        : null,
    }));

  return http.ok({ goals });
};
