'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { computeRank } = require('../../layers/shared/nodejs/node_modules/lifemaxxing-shared/rankLadder');

test('starting user is Low Tier Normie 1', () => {
  const rank = computeRank({ totalXP: 0, activeDaysLast30: 0, activeDaysLast60: 0, categoryStreakDays: [], eliteWeeksCount: 0 });
  assert.equal(rank.key, 'LOW_TIER_NORMIE_1');
});

test('plain XP thresholds promote through the normie ladder', () => {
  assert.equal(computeRank({ totalXP: 100, categoryStreakDays: [] }).key, 'LOW_TIER_NORMIE_2');
  assert.equal(computeRank({ totalXP: 4200, categoryStreakDays: [] }).key, 'HIGH_TIER_NORMIE_3');
});

test('Chad Light XP alone is NOT enough without consistency', () => {
  const rank = computeRank({
    totalXP: 8000,
    activeDaysLast30: 5, // far short of the 21-day requirement
    categoryStreakDays: [20, 16], // would otherwise satisfy the streak requirement
    eliteWeeksCount: 0,
  });
  assert.notEqual(rank.key, 'CHAD_LIGHT');
  assert.equal(rank.key, 'HIGH_TIER_NORMIE_3');
});

test('Chad Light unlocks once XP + active days + qualifying streaks are all met', () => {
  const rank = computeRank({
    totalXP: 8000,
    activeDaysLast30: 21,
    categoryStreakDays: [14, 20, 3],
    eliteWeeksCount: 0,
  });
  assert.equal(rank.key, 'CHAD_LIGHT');
});

test('Chad requires elite weeks on top of XP, active days, and long streaks', () => {
  const almostChad = computeRank({
    totalXP: 18000,
    activeDaysLast30: 21,
    activeDaysLast60: 45,
    categoryStreakDays: [30, 31, 40],
    eliteWeeksCount: 1, // short of the 4 required
  });
  assert.equal(almostChad.key, 'CHAD_LIGHT');

  const chad = computeRank({
    totalXP: 18000,
    activeDaysLast30: 21,
    activeDaysLast60: 45,
    categoryStreakDays: [30, 31, 40],
    eliteWeeksCount: 4,
  });
  assert.equal(chad.key, 'CHAD');
});
