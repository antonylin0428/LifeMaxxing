# Gamified Goals iOS App: AWS Tech Stack Plan

## App Overview

This app gamifies daily goals and personal achievements. Users complete goals, earn XP, build category streaks, rank up, add friends, and compare progress through a friends leaderboard.

The app is designed around daily self-improvement categories such as:

* Fitness / workouts
* Focus / studying / work
* Screen time discipline
* Personal goals
* Optional reflection / spiritual journey

The long-term goal is to create a fun self-improvement app where users feel motivated to stay consistent and compete with friends in a healthy way.

---

# Recommended Tech Stack

## Frontend

### iOS App

* **Language:** Swift
* **UI Framework:** SwiftUI
* **IDE:** Xcode

SwiftUI will be used to build the app screens, user flows, profile pages, task completion views, leaderboard views, and settings.

---

# AWS Backend Stack

The app will use AWS cloud services because I want to gain real experience with AWS while building a real project. This will also help me practice concepts that are useful for the AWS Solutions Architect certification.

## Core AWS Services

| Service            | Purpose                                                                                   |
| ------------------ | ----------------------------------------------------------------------------------------- |
| Amazon Cognito     | User authentication and account management                                                |
| Amazon API Gateway | Allows the iOS app to communicate with backend APIs                                       |
| AWS Lambda         | Runs backend logic like XP calculation, streak updates, rank updates, and friend requests |
| Amazon DynamoDB    | Main database for users, XP, streaks, tasks, friends, and leaderboards                    |
| Amazon CloudWatch  | Logging, debugging, and basic monitoring                                                  |
| AWS Budgets        | Cost alerts to prevent surprise charges                                                   |

---

# Recommended Architecture

```text
SwiftUI iOS App
        ↓
Amazon Cognito
        ↓
API Gateway HTTP API
        ↓
AWS Lambda
        ↓
Amazon DynamoDB
        ↓
CloudWatch Logs
```

## Why this architecture?

This stack is serverless, scalable, and beginner-friendly compared to managing servers manually.

The iOS app should not directly modify important database fields like XP, rank, or streaks. Instead, the app should send user actions to the backend, and AWS Lambda should calculate the correct updates.

Example:

```text
User taps "Complete Workout"
        ↓
iOS app sends request to API Gateway
        ↓
Lambda verifies the user
        ↓
Lambda calculates XP and streak changes
        ↓
Lambda updates DynamoDB
        ↓
Updated progress is returned to the app
```

This makes the app more secure and prevents users from cheating by directly changing their XP or rank.

---

# Core AWS Services Explained

## Amazon Cognito

Cognito handles user authentication.

It will be used for:

* Sign up
* Login
* User identity
* Password reset
* Possibly Sign in with Apple later

Each user will receive a unique user ID from Cognito. That user ID will connect their account to their data in DynamoDB.

---

## Amazon DynamoDB

DynamoDB will be the main database.

It will store:

* User profiles
* Total XP
* Rank
* Category streaks
* Daily logs
* XP events
* Friend requests
* Friendships
* Leaderboard data

DynamoDB is a good fit because this app mostly needs fast reads and writes of small pieces of data.

Example data:

```text
User opens app → load profile
User completes goal → update XP
User adds friend → create friend request
User views leaderboard → load friend rankings
```

---

## AWS Lambda

Lambda will run backend logic without needing to manage a server.

Lambda functions will handle:

* Completing a task
* Calculating XP
* Applying streak multipliers
* Updating ranks
* Creating daily logs
* Sending friend requests
* Accepting friend requests
* Loading leaderboard data

The app should not calculate final XP by itself. The backend should be the trusted source.

---

## API Gateway

API Gateway lets the iOS app talk to the backend.

Recommended version:

* **API Gateway HTTP API**

HTTP API is usually simpler and cheaper than REST API for this type of mobile app.

Example API routes:

```text
POST /complete-task
GET /user-profile
GET /daily-log
POST /friend-request
POST /accept-friend
GET /friends-leaderboard
```

---

## CloudWatch

CloudWatch will be used for logs and debugging.

Use it to check:

* Lambda errors
* Failed API requests
* Backend bugs
* Unexpected XP calculation issues

To control costs, logs should have a short retention period, such as 7 or 14 days.

---

## AWS Budgets

AWS Budgets should be set up immediately to avoid surprise charges.

Suggested budget alerts:

```text
$1 alert
$5 alert
$10 alert
```

This is important because AWS is usage-based. Even though the app should be very cheap early on, budget alerts help catch mistakes.

---

# Services Not Needed for MVP

These AWS services should not be used at the beginning:

| Service       | Why not needed yet                                     |
| ------------- | ------------------------------------------------------ |
| EC2           | No need to manage servers                              |
| RDS           | DynamoDB is simpler for this app                       |
| VPC           | Not needed for basic serverless MVP                    |
| NAT Gateway   | Can become expensive and unnecessary                   |
| Load Balancer | No servers to balance                                  |
| ECS / EKS     | Too complex for MVP                                    |
| ElastiCache   | Not needed until leaderboards become large             |
| Redshift      | Only useful later for analytics                        |
| Neptune       | Graph database is overkill for basic friends system    |
| S3            | Only needed later for profile pictures or file uploads |

The MVP should stay lean.

---

# Cost Expectations

## Upfront Cost

There should be no upfront AWS database/server cost.

DynamoDB, Lambda, API Gateway, and Cognito are usage-based. For a small MVP, the cost should be very low.

## Expected Early Costs

| Stage                   | Estimated Backend Cost |
| ----------------------- | ---------------------: |
| Personal testing        |                     $0 |
| Small beta with friends |            $0–$2/month |
| Early public app        |           $0–$10/month |
| Larger user base        |            Usage-based |

The separate unavoidable iOS cost is the Apple Developer Program fee if the app is published to the App Store.

---

# Free Alternatives

There are free alternatives, but they teach less AWS.

## Option 1: Local-Only App

Use SwiftData or Core Data.

Pros:

* Completely free
* Easy to build core XP/rank system
* No backend needed

Cons:

* No accounts
* No friends
* No cloud sync
* No leaderboard

This is good for a prototype but not the full app.

## Option 2: Firebase Free Plan

Pros:

* Easier than AWS
* Authentication and database included
* Good for fast MVPs

Cons:

* Less AWS experience
* Less useful for AWS certification practice

## Option 3: Supabase Free Plan

Pros:

* Free to start
* Uses Postgres
* Includes auth and database

Cons:

* Less AWS experience
* Slightly different backend model

## Final Decision

Even though there are free alternatives, I want to use AWS because:

* I am studying AWS Solutions Architect concepts
* I want hands-on experience with real cloud services
* AWS is highly valued professionally
* This app can become a strong portfolio project

The goal is to use AWS carefully without overbuilding.

---

# MVP Feature List

The first version should include:

## Authentication

* User sign up
* User login
* User profile creation
* Username setup

## Core Goal System

* Create/select goal categories
* Complete daily goals
* Earn XP
* Track daily progress
* View today’s completed tasks

## XP and Ranking

* Lifetime XP
* Overall rank
* Category streaks
* Streak multipliers
* Rank-up logic

The detailed XP system is explained in the separate Word document. In short, users earn XP from daily goals, category streaks increase XP multipliers, multipliers cap at day 7, and top ranks require consistency.

## Friends

* Search/add friends
* Send friend requests
* Accept/decline friend requests
* View friends list

## Leaderboard

* Friends leaderboard
* Show rank, XP, and streak highlights

---

# XP System Summary

The app uses a gamified ranking system.

Ranks include:

```text
Low Tier Normie 1
Low Tier Normie 2
Low Tier Normie 3
Mid Tier Normie 1
Mid Tier Normie 2
Mid Tier Normie 3
High Tier Normie 1
High Tier Normie 2
High Tier Normie 3
Chad Light
Chad
```

Core XP rules:

* Users earn XP by completing goals.
* Each category has its own streak.
* Streaks increase XP only for that category.
* XP multipliers cap at the 7th day.
* The streak number can continue increasing after day 7.
* Chad Light and Chad require both XP and consistency.
* Users should not be able to buy XP or ranks.

The Word document should be used as the source of truth for the full XP/ranking/streak system.

---

# Security and Anti-Cheat Rules

The iOS app should not directly edit important fields like:

```text
totalXP
rank
seasonXP
currentStreak
bestStreak
leaderboardScore
```

Instead:

```text
The app submits actions.
Lambda validates the action.
Lambda calculates XP.
Lambda updates DynamoDB.
```

This prevents users from cheating by sending fake requests like:

```text
Set my XP to 999999
Set my rank to Chad
Give me a 100-day streak
```

---

# Suggested DynamoDB Tables

## Users

Stores public profile and overall progress.

Fields:

```text
userId
username
displayName
totalXP
seasonXP
rank
createdAt
lastActiveAt
```

## CategoryStats

Stores each user’s progress in each category.

Fields:

```text
userId
categoryId
categoryName
totalXP
currentStreak
bestStreak
lastCompletedDate
multiplier
```

## DailyLogs

Stores daily progress.

Fields:

```text
userId
date
totalXP
completedCategories
completedTasks
createdAt
```

## XPEvents

Stores XP history.

Fields:

```text
eventId
userId
categoryId
source
baseXP
multiplier
finalXP
createdAt
```

## FriendRequests

Stores pending friend requests.

Fields:

```text
requestId
fromUserId
toUserId
status
createdAt
```

## Friendships

Stores accepted friendships.

Fields:

```text
userId
friendUserId
createdAt
```

## Leaderboards

Stores leaderboard data.

Fields:

```text
leaderboardId
userId
username
rank
totalXP
seasonXP
weeklyXP
updatedAt
```

---

# Suggested Lambda Functions

```text
createUserProfile
getUserProfile
completeTask
calculateXP
updateCategoryStreak
updateRank
getDailyLog
sendFriendRequest
acceptFriendRequest
declineFriendRequest
getFriendsList
getFriendsLeaderboard
```

---

# Suggested SwiftUI Screens

## Authentication

* Welcome screen
* Sign up screen
* Login screen
* Create profile screen

## Main App

* Home dashboard
* Daily goals screen
* Complete goal screen
* XP/rank progress screen
* Category streaks screen
* Friends screen
* Friend requests screen
* Friends leaderboard screen
* Profile screen
* Settings screen

---

# Suggested Build Order

## Phase 1: Local UI Prototype

Build the SwiftUI screens without AWS first.

Goal:

* Make the app feel real
* Click through the main flow
* Test layout and navigation

Screens:

```text
Welcome
Login placeholder
Home dashboard
Daily goals
Profile
Leaderboard placeholder
```

## Phase 2: Add Cognito Authentication

Add real signup/login.

Goal:

* Users can create accounts
* Users can log in
* Users have unique Cognito IDs

## Phase 3: Add DynamoDB User Profiles

Create user profiles in DynamoDB.

Goal:

* Store username
* Store display name
* Store starting XP/rank

## Phase 4: Add Task Completion + XP Logic

Create the main gameplay loop.

Goal:

* User completes a task
* Lambda calculates XP
* DynamoDB updates XP/streak/rank
* App displays updated progress

## Phase 5: Add Friends

Goal:

* Send friend request
* Accept friend request
* View friend list

## Phase 6: Add Friends Leaderboard

Goal:

* Compare XP/rank with friends
* Show leaderboard sorted by XP or season XP

## Phase 7: Polish MVP

Goal:

* Improve UI
* Add error handling
* Add CloudWatch logging
* Set budget alerts
* Prepare for TestFlight

---

# Final MVP Goal

The MVP should prove that users enjoy the core loop:

```text
Complete goals
Earn XP
Build streaks
Rank up
Compare with friends
Come back tomorrow
```

Do not overbuild the first version.

Build the smallest version that makes the app fun, social, and repeatable.
