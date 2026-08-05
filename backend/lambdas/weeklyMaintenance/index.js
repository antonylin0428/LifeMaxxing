'use strict';

/**
 * Weekly maintenance — run once per week via EventBridge cron.
 *
 * Replenishes each category's streakFreeze allowance back to 1.
 * Without this, freezesAvailable drops to 0 after one use and stays there
 * forever since no code previously reset it.
 */

const { ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { ddb, TableNames } = require('lifemaxxing-shared');

exports.handler = async function () {
  let lastKey;
  let replenished = 0;
  let errors = 0;

  do {
    const scan = await ddb.send(new ScanCommand({
      TableName: TableNames.CATEGORY_STATS,
      ExclusiveStartKey: lastKey,
      ProjectionExpression: 'PK, SK',
    }));

    await Promise.allSettled(
      (scan.Items ?? []).map(async item => {
        try {
          await ddb.send(new UpdateCommand({
            TableName: TableNames.CATEGORY_STATS,
            Key: { PK: item.PK, SK: item.SK },
            UpdateExpression: 'SET freezesAvailable = :one, freezesUsedThisWeek = :zero',
            ExpressionAttributeValues: { ':one': 1, ':zero': 0 },
          }));
          replenished += 1;
        } catch (err) {
          console.error(JSON.stringify({ level: 'error', item: item.PK, error: err.message }));
          errors += 1;
        }
      })
    );

    lastKey = scan.LastEvaluatedKey;
  } while (lastKey);

  console.log(JSON.stringify({ level: 'info', message: 'Weekly maintenance complete', replenished, errors }));
  return { replenished, errors };
};
