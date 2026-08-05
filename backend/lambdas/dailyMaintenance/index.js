'use strict';

/**
 * Daily maintenance — run once per day via EventBridge cron.
 *
 * Fixes the Chad Light / Chad unreachability bug: activeDaysLast30,
 * activeDaysLast60, and eliteWeeksCount were initialised to 0 and never
 * updated, so computeRank() always gated the top two ranks at false.
 *
 * For every user profile this Lambda:
 *   1. Queries DailyLogs to count distinct active UTC days in the last 30/60 days.
 *   2. Queries XPEvents to identify elite weeks (≥ 600 XP, ≥ 3 categories) over
 *      the past 26 weeks and accumulates a lifetime eliteWeeksCount.
 *   3. Reads CategoryStats to get current streak lengths (needed for computeRank).
 *   4. Re-runs computeRank with updated stats and writes back if rank changed.
 */

const { QueryCommand, ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { ddb, TableNames } = require('lifemaxxing-shared');
const { computeRank, isEliteWeek } = require('lifemaxxing-shared');
const { todayString } = require('lifemaxxing-shared');

const MS_PER_DAY = 1000 * 60 * 60 * 24;

function daysAgoString(n) {
  return new Date(Date.now() - n * MS_PER_DAY).toISOString().slice(0, 10);
}

function isoWeekKey(dateString) {
  // Returns a string like "2026-W31" for grouping events by ISO week.
  const d = new Date(`${dateString}T12:00:00Z`);
  const dayOfWeek = d.getUTCDay() || 7; // Mon=1 … Sun=7
  const thursday = new Date(d);
  thursday.setUTCDate(d.getUTCDate() + 4 - dayOfWeek);
  const year = thursday.getUTCFullYear();
  const startOfYear = new Date(Date.UTC(year, 0, 1));
  const week = Math.ceil(((thursday - startOfYear) / MS_PER_DAY + 1) / 7);
  return `${year}-W${String(week).padStart(2, '0')}`;
}

async function queryAllPages(params) {
  const items = [];
  let lastKey;
  do {
    const res = await ddb.send(new QueryCommand({ ...params, ExclusiveStartKey: lastKey }));
    items.push(...(res.Items ?? []));
    lastKey = res.LastEvaluatedKey;
  } while (lastKey);
  return items;
}

async function updateUserStats(user) {
  const sub = user.PK.replace('USER#', '');
  const today = todayString();
  const thirtyDaysAgo = daysAgoString(30);
  const sixtyDaysAgo = daysAgoString(60);
  // 26 weeks ≈ 6 months — enough history to count lifetime elite weeks.
  const twentySixWeeksAgo = daysAgoString(182);

  // 1. Count active days from DailyLogs (SK = LOG#YYYY-MM-DD#categoryId).
  const logs = await queryAllPages({
    TableName: TableNames.DAILY_LOGS,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
    ExpressionAttributeValues: {
      ':pk': `USER#${sub}`,
      ':start': `LOG#${sixtyDaysAgo}`,
      ':end': `LOG#${today}z`,
    },
    ProjectionExpression: 'SK',
  });

  const activeDates = new Set(logs.map(({ SK }) => SK.slice(4, 14))); // LOG#YYYY-MM-DD#…
  const activeDaysLast30 = [...activeDates].filter(d => d >= thirtyDaysAgo).length;
  const activeDaysLast60 = activeDates.size;

  // 2. Compute eliteWeeksCount from XPEvents (SK = EVENT#isoTimestamp#uuid).
  const xpEvents = await queryAllPages({
    TableName: TableNames.XP_EVENTS,
    KeyConditionExpression: 'PK = :pk AND SK BETWEEN :start AND :end',
    ExpressionAttributeValues: {
      ':pk': `USER#${sub}`,
      ':start': `EVENT#${twentySixWeeksAgo}`,
      ':end': `EVENT#${today}z`,
    },
    ProjectionExpression: 'categoryId, finalXPAwarded, createdAt',
  });

  const weeklyStats = {};
  for (const ev of xpEvents) {
    const week = isoWeekKey(ev.createdAt.slice(0, 10));
    if (!weeklyStats[week]) weeklyStats[week] = { weeklyXP: 0, categories: new Set() };
    weeklyStats[week].weeklyXP += ev.finalXPAwarded ?? 0;
    weeklyStats[week].categories.add(ev.categoryId);
  }
  const eliteWeeksCount = Object.values(weeklyStats).filter(w =>
    isEliteWeek({ weeklyXP: w.weeklyXP, categoriesUsedThisWeek: w.categories.size })
  ).length;

  // 3. Read category streaks for computeRank's consistency check.
  const categoryStats = await queryAllPages({
    TableName: TableNames.CATEGORY_STATS,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :prefix)',
    ExpressionAttributeValues: {
      ':pk': `USER#${sub}`,
      ':prefix': 'CATEGORY#',
    },
    ProjectionExpression: 'currentStreak',
  });
  const categoryStreakDays = categoryStats.map(c => c.currentStreak ?? 0);

  // 4. Recompute rank with updated stats.
  const { key: newRank, rankIndex: newRankIndex } = computeRank({
    totalXP: user.totalXP ?? 0,
    activeDaysLast30,
    activeDaysLast60,
    categoryStreakDays,
    eliteWeeksCount,
  });

  await ddb.send(new UpdateCommand({
    TableName: TableNames.USERS,
    Key: { PK: `USER#${sub}`, SK: 'PROFILE' },
    UpdateExpression: `SET activeDaysLast30 = :d30,
                           activeDaysLast60 = :d60,
                           eliteWeeksCount  = :ew,
                           #rank            = :rank,
                           rankIndex        = :ri`,
    ExpressionAttributeNames: { '#rank': 'rank' },
    ExpressionAttributeValues: {
      ':d30': activeDaysLast30,
      ':d60': activeDaysLast60,
      ':ew': eliteWeeksCount,
      ':rank': newRank,
      ':ri': newRankIndex,
    },
  }));
}

exports.handler = async function () {
  let lastKey;
  let processed = 0;
  let errors = 0;

  do {
    const scan = await ddb.send(new ScanCommand({
      TableName: TableNames.USERS,
      FilterExpression: 'SK = :sk',
      ExpressionAttributeValues: { ':sk': 'PROFILE' },
      ExclusiveStartKey: lastKey,
      ProjectionExpression: 'PK, totalXP',
    }));

    await Promise.allSettled(
      (scan.Items ?? []).map(user =>
        updateUserStats(user).catch(err => {
          console.error(JSON.stringify({ level: 'error', user: user.PK, error: err.message }));
          errors += 1;
        })
      )
    );

    processed += (scan.Items ?? []).length;
    lastKey = scan.LastEvaluatedKey;
  } while (lastKey);

  console.log(JSON.stringify({ level: 'info', message: 'Daily maintenance complete', processed, errors }));
  return { processed, errors };
};
