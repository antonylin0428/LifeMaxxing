'use strict';

const { GetCommand, QueryCommand, PutCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

const VALID_TRACKING_TYPES = new Set(['photo', 'text', 'both']);

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  const communityId = event.pathParameters?.communityId;
  if (!communityId) return http.badRequest('communityId path parameter required');

  const { Item: community } = await ddb.send(new GetCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: 'PROFILE' },
  }));
  if (!community) return http.notFound('Community not found');
  if (community.createdBy !== userSub) return http.forbidden('Only the community creator can manage goals');

  let body;
  try { body = JSON.parse(event.body || '{}'); } catch { return http.badRequest('Invalid JSON'); }

  const { goals } = body;
  if (!Array.isArray(goals)) return http.badRequest('goals must be an array');
  if (goals.length > 20) return http.badRequest('Maximum 20 goals per community');

  for (const g of goals) {
    if (!g.goalId || typeof g.goalId !== 'string') return http.badRequest('Each goal must have a goalId string');
    if (!g.name || typeof g.name !== 'string' || g.name.trim().length === 0) return http.badRequest('Each goal must have a non-empty name');
    if (g.name.length > 60) return http.badRequest('Goal name must be 60 characters or fewer');
    if (!VALID_TRACKING_TYPES.has(g.trackingType)) return http.badRequest('trackingType must be photo, text, or both');
  }

  // Fetch existing goals to find which ones to delete
  const existingRes = await ddb.send(new QueryCommand({
    TableName: TableNames.COMMUNITIES,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
    ExpressionAttributeValues: {
      ':pk': `COMMUNITY#${communityId}`,
      ':start': 'GOAL#',
      ':end': 'GOAL#~',
    },
    ProjectionExpression: 'goalId',
  }));

  const newGoalIds = new Set(goals.map(g => g.goalId));
  const toDelete = (existingRes.Items || []).filter(g => !newGoalIds.has(g.goalId));
  const now = new Date().toISOString();

  await Promise.all([
    ...toDelete.map(g =>
      ddb.send(new DeleteCommand({
        TableName: TableNames.COMMUNITIES,
        Key: { PK: `COMMUNITY#${communityId}`, SK: `GOAL#${g.goalId}` },
      }))
    ),
    ...goals.map((g, idx) =>
      ddb.send(new PutCommand({
        TableName: TableNames.COMMUNITIES,
        Item: {
          PK: `COMMUNITY#${communityId}`,
          SK: `GOAL#${g.goalId}`,
          communityId,
          goalId: g.goalId,
          name: g.name.trim(),
          description: g.description?.trim() || null,
          emoji: g.emoji || '⭐',
          trackingType: g.trackingType,
          order: g.order ?? idx,
          isActive: true,
          updatedAt: now,
        },
      }))
    ),
  ]);

  return http.ok({ goals: goals.map((g, idx) => ({ ...g, order: g.order ?? idx })) });
};
