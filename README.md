# Golem

An iOS app against doomscrolling. You pick the apps that eat your time. When
you've been on them for a few minutes, the Golem steps in and covers the app
with a shield:

> **The Golem is watching**
> You've been on Instagram for 3 min. Is it worth it?
>
> [ Close app ]  [ Plead with the Golem ]

Pleading isn't free. You wait out a countdown and write down why you need
more time. Only then does the Golem give you a few more minutes.

## Getting started

Requirements: Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
xcodegen            # creates Golem.xcodeproj from project.yml
open Golem.xcodeproj
```

The Xcode project is **generated, not committed**. Whenever you add or move
files, or change targets or settings, edit `project.yml` and run `xcodegen`
again.

Run the shared-logic tests without a simulator:

```bash
cd Packages/GolemKit && swift test
```

### Running on a real iPhone

Screen Time features (the app picker, monitoring, shields) **only work on a
real device** and need the *Family Controls* capability. That capability
needs a **paid Apple Developer Program** membership.

1. Join the Apple Developer Program.
2. Put your team ID in `DEVELOPMENT_TEAM` in `project.yml` and run `xcodegen`.
3. If the `cz.hlozanek.golem` bundle IDs or `group.cz.hlozanek.golem` App Group
   are taken, change them in `project.yml` **and** in `AppGroup.id`
   (`Packages/GolemKit/Sources/GolemKit/Settings/SharedStore.swift`).
4. Build to your phone from Xcode.

Before you can publish on the App Store, request the Family Controls
*distribution* entitlement from Apple. Do it for every target.

## Where things live

```
project.yml                 Xcode project definition (source of truth)
Golem/                      The app you open
  App/                      Entry point + GolemModel (state & actions)
  Screens/                  SwiftUI screens
Extensions/                 Small programs iOS runs on Golem's behalf
  Monitor/                  Woken up when a usage limit is reached
  ShieldConfiguration/      Draws the shield screen
  ShieldAction/             Handles the shield's buttons
Packages/GolemKit/          Code shared by the app and all extensions
  Settings/                 What the user can tune + shared storage
  Plea/                     Plea rules and every sentence the Golem says
  ScreenTime/               Thin wrappers around Apple's Screen Time APIs
docs/                       How it works and why
```

## Common changes

| I want to…                         | Edit                                       |
|------------------------------------|--------------------------------------------|
| Change what the Golem says         | `GolemKit/Plea/GolemVoice.swift`           |
| Change how pleading works          | `GolemKit/Plea/PleaRules.swift`            |
| Add a new setting                  | `GolemKit/Settings/GolemSettings.swift`    |
| Change the shield's look           | `Extensions/ShieldConfiguration/`          |
| Change what happens at the limit   | `Extensions/Monitor/GolemMonitor.swift`    |

More detail: [docs/architecture.md](docs/architecture.md) and
[docs/decisions.md](docs/decisions.md).
