'use strict';

const { randomUUID } = require('crypto');
const { GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

const MAX_NAME_LENGTH = 60;
const MAX_DESCRIPTION_LENGTH = 280;

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  const { Item: user } = await ddb.send(new GetCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
  }));
  if (!user) return http.notFound('User profile not found');

  if (user.hasCommunityAccess !== true) {
    return http.forbidden('Creating communities requires purchasing community access');
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return http.badRequest('Request body must be valid JSON');
  }

  const name = typeof body.name === 'string' ? body.name.trim() : '';
  if (!name || name.length > MAX_NAME_LENGTH) {
    return http.badRequest(`name is required (1-${MAX_NAME_LENGTH} characters)`);
  }
  const description = typeof body.description === 'string' ? body.description.trim() : '';
  if (description.length > MAX_DESCRIPTION_LENGTH) {
    return http.badRequest(`description must be ${MAX_DESCRIPTION_LENGTH} characters or fewer`);
  }

  const communityId = randomUUID();
  const nowIso = new Date().toISOString();
  const communityProfile = {
    PK: `COMMUNITY#${communityId}`,
    SK: 'PROFILE',
    communityId,
    name,
    description: description || null,
    createdBy: userSub,
    createdByUsername: user.username,
    createdAt: nowIso,
    memberCount: 1,
  };

  // Write community profile (conditional to prevent collision on UUID reuse)
  await ddb.send(new PutCommand({
    TableName: TableNames.COMMUNITIES,
    Item: communityProfile,
    ConditionExpression: 'attribute_not_exists(PK)',
  }));

  // Add creator as first member (GSI1 enables listMyCommunities queries)
  await ddb.send(new PutCommand({
    TableName: TableNames.COMMUNITIES,
    Item: {
      PK: `COMMUNITY#${communityId}`,
      SK: `MEMBER#${userSub}`,
      GSI1PK: `USER#${userSub}`,
      GSI1SK: `COMMUNITY#${communityId}`,
      userSub,
      communityId,
      joinedAt: nowIso,
    },
  }));

  const { PK, SK, ...response } = communityProfile;
  return http.ok(response);
};
