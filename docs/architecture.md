# How Golem works

iOS doesn't let an app see which other app is open. Golem gets that
information in two ways:

- **Shortcuts automations** ("When Instagram is opened → Golem: App Opened")
  tell it exactly when you enter and leave a group's apps. This drives the
  timer and the Dynamic Island. It works in both flavours.
- **Screen Time** (full `Golem` flavour only) counts usage in whole minutes
  and can **block** apps with a shield. iOS runs small extensions for it, in
  separate processes, which share state through an **App Group** (`SharedStore`).

## The pieces

| Piece                      | Framework         | Job                                                  |
|----------------------------|-------------------|------------------------------------------------------|
| Golem app                  | SwiftUI           | Groups, settings, setup guide                        |
| `AppOpenedIntent` / `AppClosedIntent` | AppIntents | Shortcuts actions; start/pause a group's timer |
| `SessionCoordinator`       | —                 | On open/close: timer, Dynamic Island, pop-up at limit  |
| `GolemWidgets`             | WidgetKit         | Draws the Dynamic Island / Lock Screen timer         |
| `GolemMonitor`             | DeviceActivity    | Screen Time: woken when a group's limit is reached   |
| `GolemShieldConfiguration` | ManagedSettingsUI | Screen Time: texts and buttons of the shield         |
| `GolemShieldAction`        | ManagedSettings   | Screen Time: what the shield's buttons do            |
| `GolemKit`                 | —                 | Shared settings, timers, rules, wording, glue        |

## The timer loop (both flavours)

```
 You open Instagram
        │  Shortcuts automation → AppOpenedIntent(Reels)
        ▼
 SessionCoordinator.appOpened
        │  SessionTracker: Reels starts/continues (other groups pause)
        │  LiveTimer.show → the timer starts: white eyes + mm:ss, and in the
        │  moment iOS shows it large, his "waking" line (GolemLines)
        │  iOS 26+: stages are booked to start by themselves, each popping
        │  the Island open with a new line: orange at 80% of the limit, red
        │  at the limit and at +1 and +2 min (5 Live Activities is the cap).
        │  Older iOS: it turns red at the limit (stale date) + a notification
        ▼
 You switch to TikTok (same group)
        │  "closed" + "opened" arrive within a moment → one visit, timer keeps going
        ▼
 Time runs out → the Island pops open, red: "Why are you keeping me awake?"
        │  (older iOS: it turns red, plus the notification)
        │  Reopening the app past the limit pops it open again (and rebooks).
        │  It stays red, counting how far over you are. Nothing to earn.
        ▼
 You leave → the time flows back until you're under the limit again

 You close the app → AppClosedIntent: timer pauses and the Live Activity
 ends, so nothing stays on the Lock Screen. (Each new visit's timer drops
 down large for a moment as it starts; iOS decides that.)
 Opening Golem stops every timer (no watched app can be open then).
 While you're away, used time flows back: a second for every second away.

 After each open/close (and whenever Golem is open), LineWriter tops up
 the golem's lines with the on-device model: two batches per moment, the
 spare taking over at 80% used. SessionCoordinator handles events one at
 a time, so a late "opened" can't undo a "closed".
```

The rules for counting (switching, resting) live in `GroupSession` and
are covered by unit tests.

## The blocking loop (full flavour)

```
 "Start blocking" → Monitoring.startAll: one all-day schedule per group
        │  a group's apps used for its limit
        ▼
 GolemMonitor → Shields.raise(group) + notification
        ▼
 Shield ── "Close app" ──▶ app closes, shield stays up
        ▼
 The shield lifts at midnight or when you stop blocking (see open questions)
```

Each group has its own named `ManagedSettingsStore` and its own
`DeviceActivityName`, so one group's shield doesn't touch the others.

## Shared state (`SharedStore`)

| Key                | Written by                     | Read by                     |
|--------------------|--------------------------------|-----------------------------|
| `settings`         | app                            | everyone                    |
| `sessions`         | Shortcuts actions, app         | app, Shortcuts actions      |
| `shieldedGroupIDs` | `Shields` (app/monitor)        | app (the golem's mood)      |

GolemLite has no App Group. There the store stays inside the app, which is
fine because the Shortcuts actions run in the app's own process.

## Limits

- **Setup by hand.** Golem can't create Shortcuts automations; the user does,
  two per group. The in-app guide walks through it.
- **No blocking without Screen Time.** GolemLite only times and nags. It
  can't stop you from scrolling past the limit.
- **Locking isn't leaving.** iOS has no lock trigger and doesn't fire
  "Is Closed" on lock, and unlocking back into the app fires no
  "Is Opened". So locked time counts until you leave the app or open Golem.
- **Screen Time counts minutes, not seconds**, and its "in a row" is
  approximated by the all-day schedule; it doesn't know about resting.
- **No Screen Time in the Simulator.** There `Capabilities.screenTime` is
  false, even in the full flavour.
