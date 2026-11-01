# How Golem works

iOS doesn't let an app see which other app is open. Golem uses Apple's Screen
Time frameworks instead. Golem tells iOS what to watch and what to do, and iOS
runs small **extensions** at the right moments. Each extension is a separate
process, so they all share state through an **App Group** (`SharedStore`).

## The pieces

| Piece                      | Framework         | Job                                             |
|----------------------------|-------------------|-------------------------------------------------|
| Golem app                  | FamilyControls    | Ask for access, pick apps, settings, pleading   |
| `GolemMonitor`             | DeviceActivity    | Woken when the usage limit is reached           |
| `GolemShieldConfiguration` | ManagedSettingsUI | Texts, colors and buttons of the shield         |
| `GolemShieldAction`        | ManagedSettings   | What the shield's buttons do                    |
| `GolemKit`                 | —                 | Shared settings, rules, wording, Screen Time glue |

## The loop

```
 You tap "Start watching"
        │  Monitoring.start(limitMinutes)
        ▼
 iOS counts usage of the watched apps
        │  limit reached
        ▼
 GolemMonitor.eventDidReachThreshold
        │  Shields.raise() + "Time's up" notification
        ▼
 Shield over the app ── "Close app" ──▶ app closes, shield stays up
        │
        │ "Plead with the Golem"
        ▼
 GolemShieldAction sends a notification (extensions can't open the app)
        │  you tap it
        ▼
 Golem app → PleaView: wait the countdown + write a reason (PleaRules)
        │  granted
        ▼
 GolemModel.grantMoreTime(): Shields.lower() + Monitoring.start(grantedMinutes)
        │
        └──▶ back to "iOS counts usage", starting from zero
```

At midnight a new monitoring interval starts and `GolemMonitor.intervalDidStart`
lowers the shield.

## Shared state (`SharedStore`)

| Key            | Written by              | Read by                  |
|----------------|-------------------------|--------------------------|
| `settings`     | app                     | app, monitor, shield     |
| `appSelection` | app                     | app, monitor (shielding) |
| `isShieldUp`   | `Shields` (app/monitor) | app (shows the plea button) |

## Limits of the Screen Time APIs

- **Minutes, not seconds.** Usage thresholds are whole minutes.
- **"In a row" is approximated.** iOS counts total usage since monitoring
  started. It doesn't track one continuous session. Golem restarts monitoring
  after each plea (`includesPastActivity: false`), so the count starts fresh.
  This still needs checking on a real device.
- **No app names in the monitor.** Apps are opaque tokens. Only the shield
  extension gets a readable name (`localizedDisplayName`), and only the app can
  draw icons (`Label(token)`).
- **One limit for the whole group.** All watched apps share one counter.
- **No simulator.** Shields and monitoring only run on a real device.
