'use strict';

const { GetCommand, PutCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
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

  // Add membership (idempotent: if already a member return success)
  try {
    await ddb.send(new PutCommand({
      TableName: TableNames.COMMUNITIES,
      Item: {
        PK: `COMMUNITY#${communityId}`,
        SK: `MEMBER#${userSub}`,
        GSI1PK: `USER#${userSub}`,
        GSI1SK: `COMMUNITY#${communityId}`,
        userSub,
        communityId,
        joinedAt: new Date().toISOString(),
      },
      ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
    }));
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      // Already a member — return success so client can proceed
      return http.ok({ joined: true });
    }
    throw err;
  }

  // Increment member count
  await ddb.send(new UpdateCommand({
    TableName: TableNames.COMMUNITIES,
    Key: { PK: `COMMUNITY#${communityId}`, SK: 'PROFILE' },
    UpdateExpression: 'ADD memberCount :one',
    ExpressionAttributeValues: { ':one': 1 },
  }));

  return http.ok({ joined: true });
};
