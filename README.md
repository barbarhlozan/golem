# Golem

An iOS app against doomscrolling. You sort your time-eating apps into
**groups**, e.g. *Social* (Instagram, TikTok) and *News* (Bluesky, X). When you
open one, a timer starts in the **Dynamic Island**. Switching between apps of
the same group keeps one timer going. When the group's time is up, the Golem
steps in:

> **The Golem is watching**
> You've been on Instagram for 5 min. Is it worth it?
>
> [ Close app ]  [ Plead with the Golem ]

Pleading isn't free. You wait out a countdown and write down why you need
more time. Only then does the Golem give you a few more minutes. Stay away
from a group long enough and its timer starts again from zero.

## Two flavours

| Scheme      | What it does                                         | Needs                       |
|-------------|------------------------------------------------------|-----------------------------|
| `GolemLite` | Group timers, Dynamic Island, plea screen            | Free Apple account; Simulator works |
| `Golem`     | All of that + Screen Time shields that block the apps | Paid Apple Developer Program, real iPhone |

They share all their code (`Capabilities.screenTime` tells them apart) and
the same bundle ID, so only one can be installed at a time.

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

### Trying it in the Simulator

Run the `GolemLite` scheme. Debug builds have a **Test without Shortcuts**
section with Open / Close buttons per group. They do exactly what the
Shortcuts automations do. Tap **Open**, swipe home, and the timer shows up in
the Dynamic Island.

### Running on your iPhone

1. Set your team in `DEVELOPMENT_TEAM` in `project.yml` and run `xcodegen`.
2. On the phone, turn on **Settings → Privacy & Security → Developer Mode**.
3. Run the `GolemLite` scheme on the phone from Xcode.
4. After the first install, trust your certificate: **Settings → General →
   VPN & Device Management**.
5. In Golem, open **Set up the Shortcuts automations** and follow the steps:
   per group, one automation for "is opened" and one for "is closed".

With a free account the app stops launching after 7 days; reinstall it.

The full `Golem` scheme needs the *Family Controls* capability, which needs
the **paid Apple Developer Program**. Before publishing on the App Store,
request the Family Controls *distribution* entitlement for every Screen Time
target.

## Where things live

```
project.yml                 Xcode project definition (source of truth)
Golem/                      The app you open (both flavours)
  App/                      Entry point, GolemModel (state & actions), Capabilities
  Intents/                  Shortcuts actions: App Opened / App Closed
  Timing/                   What happens on open/close (timer, Island, notification)
  Screens/                  SwiftUI screens
Extensions/                 Small programs iOS runs on Golem's behalf
  Widgets/                  The Dynamic Island / Lock Screen timer
  Monitor/                  Screen Time: woken when a group's limit is reached
  ShieldConfiguration/      Screen Time: draws the shield screen
  ShieldAction/             Screen Time: handles the shield's buttons
Packages/GolemKit/          Code shared by the app and all extensions
  Settings/                 Groups, settings, shared storage
  Timing/                   Group timers: open/close, breaks, pleas (unit-tested)
  LiveActivity/             Starting/stopping the Dynamic Island timer
  Plea/                     Plea rules and every sentence the Golem says
  Notifications/            "Time's up" and plea notifications
  ScreenTime/               Thin wrappers around Apple's Screen Time APIs
docs/                       How it works and why
```

## Common changes

| I want to…                         | Edit                                       |
|------------------------------------|--------------------------------------------|
| Change what the Golem says         | `GolemKit/Plea/GolemVoice.swift`           |
| Change how pleading works          | `GolemKit/Plea/PleaRules.swift`            |
| Change how the timer counts        | `GolemKit/Timing/GroupSession.swift`       |
| Add a new setting                  | `GolemKit/Settings/GolemSettings.swift`    |
| Change the Dynamic Island look     | `Extensions/Widgets/GolemLiveActivity.swift` |
| Change the shield's look           | `Extensions/ShieldConfiguration/`          |

More detail: [docs/architecture.md](docs/architecture.md) and
[docs/decisions.md](docs/decisions.md).
