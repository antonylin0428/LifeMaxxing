'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  getMultiplierForStreak,
  calculateAwardedXP,
  CATEGORIES,
} = require('../../layers/shared/nodejs/node_modules/lifemaxxing-shared/xpRules');

test('multiplier curve caps at 1.30x on day 7, never exceeds it', () => {
  assert.equal(getMultiplierForStreak(0), 1.00);
  assert.equal(getMultiplierForStreak(1), 1.00);
  assert.equal(getMultiplierForStreak(2), 1.05);
  assert.equal(getMultiplierForStreak(3), 1.10);
  assert.equal(getMultiplierForStreak(4), 1.10);
  assert.equal(getMultiplierForStreak(5), 1.20);
  assert.equal(getMultiplierForStreak(6), 1.20);
  assert.equal(getMultiplierForStreak(7), 1.30);
  assert.equal(getMultiplierForStreak(30), 1.30);
  assert.equal(getMultiplierForStreak(365), 1.30);
});

test('reference doc worked example: workout on a 7-day fitness streak = 39 XP', () => {
  const result = calculateAwardedXP({
    categoryId: CATEGORIES.FITNESS,
    streakDaysAfterThisCompletion: 7,
    categoryXPAlreadyToday: 0,
    totalXPAlreadyToday: 0,
  });
  assert.equal(result.baseXP, 30);
  assert.equal(result.multiplier, 1.30);
  assert.equal(result.finalXPAwarded, 39);
});

test('reference doc worked example: screen time goal with no streak = 25 XP', () => {
  const result = calculateAwardedXP({
    categoryId: CATEGORIES.SCREEN_DISCIPLINE,
    streakDaysAfterThisCompletion: 1,
    categoryXPAlreadyToday: 0,
    totalXPAlreadyToday: 0,
  });
  assert.equal(result.finalXPAwarded, 25);
});

test('per-category daily cap truncates XP once the category ceiling is hit', () => {
  const result = calculateAwardedXP({
    categoryId: CATEGORIES.FITNESS,
    streakDaysAfterThisCompletion: 7,
    categoryXPAlreadyToday: 50, // only 5 XP of headroom left under the 55 cap
    totalXPAlreadyToday: 0,
  });
  assert.equal(result.finalXPAwarded, 5);
  assert.equal(result.categoryCapApplied, true);
});

test('total daily cap truncates XP once the 125/day ceiling is hit, even under category cap', () => {
  const result = calculateAwardedXP({
    categoryId: CATEGORIES.FOCUS,
    streakDaysAfterThisCompletion: 1,
    categoryXPAlreadyToday: 0,
    totalXPAlreadyToday: 122, // only 3 XP of headroom left under the 125 total cap
  });
  assert.equal(result.finalXPAwarded, 3);
  assert.equal(result.dailyCapApplied, true);
});

test('unknown category is rejected rather than silently awarding XP', () => {
  assert.throws(() => calculateAwardedXP({
    categoryId: 'NOT_A_REAL_CATEGORY',
    streakDaysAfterThisCompletion: 1,
    categoryXPAlreadyToday: 0,
    totalXPAlreadyToday: 0,
  }));
});
