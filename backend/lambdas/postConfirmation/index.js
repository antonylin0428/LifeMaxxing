'use strict';

// Cognito Post Confirmation trigger: fires once, right after a user verifies
// their email. This is where the Users PROFILE item is created - the app
// never calls an API route to "create my profile," because that would be
// one more place a client could try to inject arbitrary starting values.

const { PutCommand } = require('@aws-sdk/lib-dynamodb');
const { dynamo } = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

exports.handler = async (event) => {
  const { sub, email, preferred_username: preferredUsername } = event.request.userAttributes;
  const username = preferredUsername || event.userName;
  const nowIso = new Date().toISOString();

  await ddb.send(new PutCommand({
    TableName: TableNames.USERS,
    Item: {
      PK: `USER#${sub}`,
      SK: 'PROFILE',
      GSI1PK: `USERNAME#${username}`,
      GSI1SK: 'PROFILE',
      username,
      email,
      totalXP: 0,
      seasonXP: 0,
      currentSeasonId: 'none',
      rank: 'LOW_TIER_NORMIE_1',
      rankIndex: 0,
      // Mock premium flag (see setMockPremium) - no real payments yet.
      // Gates community creation; everyone starts non-premium.
      isPremium: false,
      activeDaysLast30: 0,
      activeDaysLast60: 0,
      totalXPToday: 0,
      totalXPTodayDate: null,
      eliteWeeksCount: 0,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    // Defensive: never overwrite an existing profile if this somehow fires twice.
    ConditionExpression: 'attribute_not_exists(PK)',
  })).catch((err) => {
    if (err.name !== 'ConditionalCheckFailedException') throw err;
  });

  // Cognito triggers must return the event unchanged.
  return event;
};
