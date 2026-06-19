# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

LifeMaxxing is a "Solo Leveling"-inspired iOS app: users complete daily goals across categories (Fitness, Screen Discipline, Study/Work, Personal Goals, optional Reflection/Spiritual Journey), earn XP, build per-category streaks, rank up through a tier ladder (Low Tier Normie 1 → Chad), add friends, and compare progress on a leaderboard.

The repo has two independent halves with no shared build tooling:
- `backend/` — AWS SAM project (Cognito, API Gateway HTTP API, Lambda, DynamoDB)
- `ios/` — SwiftUI app, project generated from `project.yml` via xcodegen

A full architecture/roadmap writeup (DynamoDB schema rationale, API route table, auth flow, anti-cheat design) lives in conversation history with the project owner — the `template.yaml` and shared layer are the executable source of truth for all of it.

## Commands

### Backend (`backend/`)

```bash
node --test tests/unit/*.test.js   # run all unit tests (npm test does the same)
sam validate --region us-east-1    # lint/validate template.yaml
sam build                          # build all Lambdas + the shared layer
sam deploy --guided                # first deploy (creates real, billable AWS resources)
sam local invoke CompleteTaskFunction -e events/completeTask.json   # invoke one function locally
```

Run a single test file: `node --test tests/unit/xpRules.test.js`. Tests use Node's built-in `node:test`/`node:assert` — no test framework dependency.

### iOS (`ios/`)

```bash
xcodegen generate                                              # regenerate LifeMaxxing.xcodeproj from project.yml
xcodebuild -resolvePackageDependencies -project LifeMaxxing.xcodeproj
xcodebuild -scheme LifeMaxxing -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build
```

`LifeMaxxing.xcodeproj` is gitignored and must be regenerated with `xcodegen generate` after pulling or after editing `project.yml`. Never hand-edit the `.xcodeproj` — edit `project.yml` instead.

## Architecture

### Request flow (non-negotiable security model)

```
SwiftUI app → Cognito (auth only, no AWS credentials issued) → API Gateway HTTP API
  (Cognito JWT Authorizer) → Lambda (one function per route) → DynamoDB
```

The iOS app **never** writes `totalXP`, `rank`, or streak fields directly, and never gets AWS credentials (no Cognito Identity Pool exists in this stack). Every mutation goes through a Lambda that derives values server-side from raw "I did X" events. When touching `backend/lambdas/completeTask/index.js` or adding any new mutating route, preserve this: the request body must never contain XP/streak/rank values, only identifiers (`categoryId`, `idempotencyKey`).

Identity in every Lambda comes from `event.requestContext.authorizer.jwt.claims.sub` (see `getUserSub` in the shared layer) — never from a client-supplied `userId` field.

### Backend layout

- `backend/template.yaml` — single source of truth for all infra: Cognito User Pool/Client, HTTP API + JWT authorizer, 6 DynamoDB tables (all `PAY_PER_REQUEST`/on-demand), 13 Lambda functions with per-function least-privilege IAM (`Policies.Statement`, never a wildcard `dynamodb:*`).
- `backend/layers/shared/nodejs/node_modules/lifemaxxing-shared/` — the shared Lambda layer, plain CommonJS (no build step; `sam build` copies it as-is since there's no `Metadata.BuildMethod` on the layer resource — don't add one without checking it won't `npm ci`-wipe this hand-placed module). Modules:
  - `xpRules.js` — base XP per category, the streak multiplier curve (caps at **1.30x on day 7** — this is fixed, do not change without explicit instruction), per-category (55 XP) and total daily (125 XP) caps, `calculateAwardedXP()`.
  - `rankLadder.js` — the 11-rank ladder and `computeRank()`. Chad Light/Chad require XP **and** consistency (active days, qualifying streak lengths, elite weeks) — `meetsConsistency()` gates these, so hitting the XP threshold alone is intentionally not enough.
  - `identity.js`, `serverClock.js`, `http.js`, `dynamoClient.js` — auth claim extraction, server-side date logic (never trust client timestamps), JSON response helpers, DynamoDB Document Client + table-name env lookups.
  - Lambdas import this via `require('lifemaxxing-shared')` — resolves through the layer's `NODE_PATH` at runtime, not a local `node_modules`.
- `backend/lambdas/<name>/index.js` — one handler per API route (see route table in `template.yaml` Events blocks), plus `postConfirmation/` which is a Cognito Lambda trigger (not an API route) that creates the initial `Users` profile item right after email verification.
- `backend/lambdas/completeTask/index.js` — the core engine. Order of operations matters and is enforced via a single `TransactWriteItems` call: conditional idempotency write to `DailyLogs` → streak calc → multiplier → per-category cap → total daily cap → round → atomic write across `DailyLogs`/`XPEvents`/`CategoryStats`/`Users` → rank recompute. The conditional write's `ConditionExpression: attribute_not_exists(PK)` is what blocks duplicate same-day-same-category submissions; don't bypass it.
- `backend/tests/unit/` — pure-function tests for `xpRules.js`/`rankLadder.js` only (no AWS mocking/integration tests yet). These encode the reference doc's worked examples (e.g. a 7-day Fitness streak workout = 39 XP) — treat test failures here as a balance regression, not a test bug, unless you're deliberately rebalancing.

DynamoDB tables all use a generic `PK`/`SK` + `GSI1PK`/`GSI1SK` naming convention (not domain-specific attribute names) specifically so a future `GSI2` (season leaderboard) can be added to `Users` later without a migration — `seasonXP`/`currentSeasonId` attributes already exist on every user item, unused, for this reason. Don't "clean up" these unused-looking fields.

Friends leaderboard is **derived live** (Friendships `Query` + Users `BatchGetItem`, sorted in Lambda) rather than a denormalized leaderboard table — this is a deliberate choice to avoid fan-out writes on every XP change, not an oversight.

### iOS layout

MVVM. `App/` (AppState + Constants — Constants.swift holds `REPLACE_ME` placeholders for the API base URL and Cognito IDs that get filled in after `sam deploy`), `Models/` (Codable structs mirroring Lambda JSON responses 1:1), `Views/` (grouped by feature: Onboarding, CategorySetup, Home, Profile, Friends), `ViewModels/` (`@Observable` classes owning networking + state), `Services/` (`AuthService` wraps Amplify Swift for Cognito SRP auth — don't hand-roll SRP; `APIClient` is the single place that attaches the Cognito **Access token** (not ID token) as `Authorization: Bearer`; `TasksAPI`/`ProfileAPI`/`FriendsAPI` are thin per-domain wrappers over `APIClient`).

UI must only ever render XP/streak/rank values that came back in a decoded server response (e.g. `CompleteTaskResult`) — never compute or guess them client-side, matching the backend security model above.

`AuthService.configure()` builds the Amplify `AuthCategoryConfiguration` programmatically from `Constants` (no `amplifyconfiguration.json` file) — if you add Amplify plugins/config, keep building nested `JSONValue` literals via an explicit intermediate `let` with a type annotation; inlining them deeply nested directly as a function argument fails Swift's type inference (`JSONValue` vs `Any` ambiguity).
