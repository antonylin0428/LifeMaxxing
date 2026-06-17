'use strict';

const { GetCommand, TransactWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { randomUUID } = require('node:crypto');
const {
  getUserSub,
  isValidCategory,
  calculateAwardedXP,
  computeRank,
  todayString,
  daysBetween,
  http,
  dynamo,
} = require('lifemaxxing-shared');

const { ddb, TableNames } = dynamo;

// Fitness rest days don't break the streak; every other category breaks on
// any missed scheduled day. MVP keeps this as a flat per-category rule.
const REST_DAY_ELIGIBLE_CATEGORIES = new Set(['FITNESS']);

exports.handler = async (event) => {
  let userSub;
  try {
    userSub = getUserSub(event);
  } catch {
    return http.unauthorized('Missing or invalid identity claim');
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return http.badRequest('Request body must be valid JSON');
  }

  const { categoryId, idempotencyKey } = body;
  if (!categoryId || !isValidCategory(categoryId)) {
    return http.badRequest('categoryId is required and must be a known category');
  }
  if (!idempotencyKey || typeof idempotencyKey !== 'string') {
    return http.badRequest('idempotencyKey is required');
  }

  const serverDate = todayString();
  const dailyLogPK = `USER#${userSub}`;
  const dailyLogSK = `LOG#${serverDate}#${categoryId}`;

  // Step 1: read current CategoryStats and Users state to compute the new streak/XP.
  const [categoryStatsRes, userRes] = await Promise.all([
    ddb.send(new GetCommand({
      TableName: TableNames.CATEGORY_STATS,
      Key: { PK: `USER#${userSub}`, SK: `CATEGORY#${categoryId}` },
    })),
    ddb.send(new GetCommand({
      TableName: TableNames.USERS,
      Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
    })),
  ]);

  const categoryStats = categoryStatsRes.Item || {
    PK: `USER#${userSub}`,
    SK: `CATEGORY#${categoryId}`,
    currentStreak: 0,
    longestStreak: 0,
    lastCompletedDate: null,
    categoryXPToday: 0,
    lastXPDate: null,
    freezesAvailable: 1,
    freezesUsedThisWeek: 0,
  };
  const user = userRes.Item;
  if (!user) {
    // Profile rows are created by the Cognito PostConfirmation trigger
    // (lambdas/postConfirmation) right after sign-up - this should be
    // unreachable in normal operation.
    return http.notFound('User profile not found');
  }

  // Reset the per-category daily cap counter if it's a new day.
  const categoryXPAlreadyToday = categoryStats.lastXPDate === serverDate ? categoryStats.categoryXPToday : 0;
  const totalXPAlreadyToday = user.totalXPTodayDate === serverDate ? user.totalXPToday : 0;

  // Step 2: compute the new streak count.
  let newStreak;
  if (!categoryStats.lastCompletedDate) {
    newStreak = 1;
  } else {
    const gap = daysBetween(categoryStats.lastCompletedDate, serverDate);
    if (gap === 0) {
      // Idempotency PutItem below will reject this as a duplicate anyway.
      newStreak = categoryStats.currentStreak;
    } else if (gap === 1) {
      newStreak = categoryStats.currentStreak + 1;
    } else if (REST_DAY_ELIGIBLE_CATEGORIES.has(categoryId) && gap <= 2) {
      // One planned rest day does not break a Fitness streak.
      newStreak = categoryStats.currentStreak + 1;
    } else {
      newStreak = 1; // streak broken
    }
  }

  const xp = calculateAwardedXP({
    categoryId,
    streakDaysAfterThisCompletion: newStreak,
    categoryXPAlreadyToday,
    totalXPAlreadyToday,
  });

  const newTotalXP = user.totalXP + xp.finalXPAwarded;
  const newRank = computeRank({
    totalXP: newTotalXP,
    activeDaysLast30: user.activeDaysLast30 || 0,
    activeDaysLast60: user.activeDaysLast60 || 0,
    categoryStreakDays: [newStreak], // MVP: full cross-category streak snapshot is a post-MVP enrichment
    eliteWeeksCount: user.eliteWeeksCount || 0,
  });

  const nowIso = new Date().toISOString();

  // Step 3: atomic write. The conditional Put on DailyLogs is the
  // idempotency gate - if this user already completed this category today,
  // the whole transaction fails with no XP awarded.
  try {
    await ddb.send(new TransactWriteCommand({
      TransactItems: [
        {
          Put: {
            TableName: TableNames.DAILY_LOGS,
            Item: {
              PK: dailyLogPK,
              SK: dailyLogSK,
              idempotencyKey,
              xpAwarded: xp.finalXPAwarded,
              completedAtServerTime: nowIso,
            },
            ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)',
          },
        },
        {
          Put: {
            TableName: TableNames.XP_EVENTS,
            Item: {
              PK: `USER#${userSub}`,
              SK: `EVENT#${nowIso}#${randomUUID()}`,
              categoryId,
              baseXP: xp.baseXP,
              multiplierApplied: xp.multiplier,
              xpAfterMultiplier: xp.xpAfterMultiplier,
              categoryCapApplied: xp.categoryCapApplied,
              dailyCapApplied: xp.dailyCapApplied,
              finalXPAwarded: xp.finalXPAwarded,
              eventType: 'TASK_COMPLETE',
              idempotencyKey,
            },
          },
        },
        {
          Put: {
            TableName: TableNames.CATEGORY_STATS,
            Item: {
              ...categoryStats,
              currentStreak: newStreak,
              longestStreak: Math.max(categoryStats.longestStreak, newStreak),
              lastCompletedDate: serverDate,
              multiplierCache: xp.multiplier,
              categoryXPToday: categoryXPAlreadyToday + xp.finalXPAwarded,
              lastXPDate: serverDate,
            },
          },
        },
        {
          Update: {
            TableName: TableNames.USERS,
            Key: { PK: `USER#${userSub}`, SK: 'PROFILE' },
            UpdateExpression: 'SET totalXP = :newTotalXP, totalXPToday = :newTotalXPToday, totalXPTodayDate = :serverDate, rank = :rankLabel, rankIndex = :rankIndex, updatedAt = :nowIso',
            ExpressionAttributeValues: {
              ':newTotalXP': newTotalXP,
              ':newTotalXPToday': totalXPAlreadyToday + xp.finalXPAwarded,
              ':serverDate': serverDate,
              ':rankLabel': newRank.key,
              ':rankIndex': newRank.rankIndex,
              ':nowIso': nowIso,
            },
          },
        },
      ],
    }));
  } catch (err) {
    if (err.name === 'TransactionCanceledException') {
      return http.conflict('This category was already completed today');
    }
    console.error('completeTask transaction failed', err);
    return http.serverError();
  }

  return http.ok({
    finalXPAwarded: xp.finalXPAwarded,
    newTotalXP,
    newStreak,
    newMultiplier: xp.multiplier,
    newRank: newRank.key,
    rankChanged: newRank.key !== user.rank,
    categoryXPRemainingToday: Math.max(0, 55 - (categoryXPAlreadyToday + xp.finalXPAwarded)),
    totalXPRemainingToday: Math.max(0, 125 - (totalXPAlreadyToday + xp.finalXPAwarded)),
  });
};
