'use strict';

// Community creation is premium-gated. The frontend hides the Create
// Community screen from non-premium users, but that's a UX nicety only -
// this check is the actual enforcement, same as every other mutation in
// this app: never trust the client, the server decides.

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

  if (user.isPremium !== true) {
    return http.forbidden('Creating communities requires a premium account');
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
  const community = {
    PK: `COMMUNITY#${communityId}`,
    SK: 'PROFILE',
    communityId,
    name,
    description: description || null,
    createdBy: userSub,
    createdByUsername: user.username,
    createdAt: nowIso,
  };

  await ddb.send(new PutCommand({
    TableName: TableNames.COMMUNITIES,
    Item: community,
    ConditionExpression: 'attribute_not_exists(PK)',
  }));

  const { PK, SK, ...response } = community;
  return http.ok(response);
};
