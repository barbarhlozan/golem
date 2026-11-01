# Decisions

Short records of why things are the way they are. Add new ones at the bottom.

## 1. Screen Time APIs, not Shortcuts automations (2026-11-01)

The original idea came from a Shortcuts automation that starts a stopwatch
when a social app opens. Shortcuts gives exact second-by-second timing, but
every user has to set up automations by hand, and it can only notify, never
block. The Screen Time APIs give a native app picker and a real shield with
buttons. The trade-offs: timing in minutes, a paid developer account, and
Apple's approval of the Family Controls entitlement before App Store release.
A Shortcuts integration can still be added later for exact timing.

## 2. XcodeGen instead of a committed .xcodeproj (2026-11-01)

`project.yml` is short and readable, and it never causes merge conflicts.
The `.xcodeproj` and the generated Info.plist / entitlements files are
ignored by git. Cost: run `xcodegen` after adding files or changing targets.

## 3. Shared code in a local Swift package (2026-11-01)

The app and three extensions all need the same settings, rules and wording.
`Packages/GolemKit` holds them. Its plain-Swift parts also build on macOS, so
`swift test` runs in seconds. The Screen Time wrappers are wrapped in
`#if os(iOS)`.

## 4. Friction-first pleading (2026-11-01)

A successful plea needs a countdown wait **and** a written reason. Each plea
grants a fixed number of minutes. All of it is configurable in `PleaRules`.
Escalating cost (each plea in a row gets harder) is a possible next step.

## Open questions

- After **Close app**, the shield stays up until you plead or until midnight.
  Should it lift on its own after a break (for example 15 minutes) instead,
  so "in a row" really means in a row?
- Should each app get its own limit, instead of one shared counter?
- Does restarting monitoring really reset the count on device? Verify once a
  paid account is available.
