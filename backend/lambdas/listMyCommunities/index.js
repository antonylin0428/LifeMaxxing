'use strict';

const { QueryCommand, BatchGetCommand } = require('@aws-sdk/lib-dynamodb');
const { getUserSub, http, dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  let userSub;
  try { userSub = getUserSub(event); } catch { return http.unauthorized('Missing or invalid identity claim'); }

  // Query all communities this user belongs to via GSI1
  const membershipRes = await ddb.send(new QueryCommand({
    TableName: TableNames.COMMUNITIES,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :pk AND begins_with(GSI1SK, :prefix)',
    ExpressionAttributeValues: {
      ':pk': `USER#${userSub}`,
      ':prefix': 'COMMUNITY#',
    },
  }));

  const memberships = membershipRes.Items || [];
  if (memberships.length === 0) return http.ok({ communities: [] });

  const communityIds = memberships.map((m) => m.communityId);

  // BatchGetItem the community profiles
  const { Responses } = await ddb.send(new BatchGetCommand({
    RequestItems: {
      [TableNames.COMMUNITIES]: {
        Keys: communityIds.map((id) => ({ PK: `COMMUNITY#${id}`, SK: 'PROFILE' })),
      },
    },
  }));

  const communities = (Responses?.[TableNames.COMMUNITIES] || [])
    .map(({ PK, SK, ...c }) => c)
    .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));

  return http.ok({ communities });
};
