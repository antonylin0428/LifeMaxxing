'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  todayString,
  isValidTimezone,
  DEFAULT_TIMEZONE,
} = require('../../layers/shared/nodejs/node_modules/lifemaxxing-shared/serverClock');

test('todayString defaults to UTC when no timezone is given', () => {
  const date = new Date('2026-01-15T23:30:00Z');
  assert.equal(todayString(undefined, date), '2026-01-15');
});

test('todayString falls back to UTC for an invalid/garbage timezone', () => {
  const date = new Date('2026-01-15T23:30:00Z');
  assert.equal(todayString('Not/A_Zone', date), todayString(DEFAULT_TIMEZONE, date));
});

test('todayString rolls over at local midnight, not UTC midnight', () => {
  // 23:30 UTC on Jan 15 is already 15:30 Jan 16 in Tokyo (UTC+9) ...
  const laterInTokyo = new Date('2026-01-15T23:30:00Z');
  assert.equal(todayString('Asia/Tokyo', laterInTokyo), '2026-01-16');

  // ... and still Jan 15 at 15:30 in Los Angeles (UTC-8 in January).
  const earlierInLA = new Date('2026-01-15T23:30:00Z');
  assert.equal(todayString('America/Los_Angeles', earlierInLA), '2026-01-15');
});

test('isValidTimezone accepts real IANA identifiers and rejects junk', () => {
  assert.equal(isValidTimezone('America/Los_Angeles'), true);
  assert.equal(isValidTimezone('UTC'), true);
  assert.equal(isValidTimezone('Not/A_Zone'), false);
  assert.equal(isValidTimezone(''), false);
  assert.equal(isValidTimezone(null), false);
  assert.equal(isValidTimezone(42), false);
});
