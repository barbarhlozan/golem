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

## 5. Hybrid: Shortcuts for timing, Screen Time for blocking (2026-11-01)

Revisits decision 1. The owner wanted a live timer in the Dynamic Island
that appears when you open a watched app. Only the app itself, a server push,
or a Shortcuts action can start a Live Activity, and Screen Time never says
when an app opens. So the "app opened / closed" Shortcuts automations now
drive an exact timer and the Island, and Screen Time stays for the shield.
An always-on Live Activity fed by Screen Time minute events was considered.
It would occupy the Island all day, can't know which group is in front, and
couldn't be verified without a paid account, so it wasn't built.

## 6. Groups with their own timer and limit (2026-11-01)

Apps are sorted into groups (e.g. Social, News). Apps in one group share a
timer: Instagram → TikTok → Instagram is one session. Each group has its own
limit, and the plea rules are shared. Only one group runs at a time. A group's
timer resets after a break (default 10 min, adjustable). "Closed" and
"opened" during a switch arrive within a moment of each other, in either
order. A "closed" within 3 s of a second "opened" is ignored.

## 7. Two flavours: Golem and GolemLite (2026-11-01)

A free Apple account can't sign the Family Controls capability, which blocks
every Screen Time target. `GolemLite` is the same app without Screen Time
(no extensions, no entitlements), so it runs on the owner's iPhone and in the
Simulator today. Both flavours share sources and the bundle ID. The
`SCREEN_TIME` compile flag plus `Capabilities.screenTime` switch the
Screen Time parts on.

## 8. Visual style: ink on paper, one hand-drawn golem (2026-11-01)

The owner wanted iOS's clean look with a bit more character, in a
hand-drawn / doodle direction. So the app stays native SwiftUI (`Form`s,
system controls) and changes only a few things: the owner's own golem drawing
(the icon, the plea screen, later the empty states), black ink as the tint
instead of iOS blue, a warm off-white "paper" background, rounded system
type for body text, and the blackletter UnifrakturMaguntia for big headings,
a nod to the golem's old-Prague roots. The font is free (OFL), so it's
bundled in `Golem/Resources/Fonts` with its license. It's only used large,
because blackletter is hard to read when small. Basilea was considered but
needs a paid embedding license. Optima was tried and felt too formal. The icon is plain white, like the drawing on paper. The dark and tinted
icon variants have a transparent background, so iOS draws its own backdrop.
Everything lives in `Golem/Design/Theme.swift` and the asset catalog colors
`Ink`, `Paper` and `Card`, so screens never use raw colors. The source
drawing is `Design/golem.png`, and `Design/make-icons.sh` regenerates the
icon and in-app images from it. `Design/golem-eye.png` is the Dynamic Island
glyph, a single-colour template image.

## Open questions

- After **Close app** on the shield, the shield stays up until you plead or
  until midnight. Should it lift on its own after the break length, matching
  the timer's break reset?
- In GolemLite, nothing stops you once the time is up. Should the
  automation itself open Golem's plea screen (e.g. an "If over limit → Open
  Golem" step), instead of relying on the notification?
- Does restarting Screen Time monitoring really reset the count on a device?
  Verify once a paid account is available.
