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

Apps are sorted into groups the user creates (Golem starts with Reels
and Feeds as examples; one group per app works too). Apps in one group share a
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
needs a paid embedding license. Optima was tried and felt too formal. The
comic-like Freckle Face was compared side by side on a phone, and the owner
preferred blackletter. The icon is plain white, like the drawing on paper. The dark and tinted
icon variants have a transparent background, so iOS draws its own backdrop.
Everything lives in `Golem/Design/Theme.swift` and the asset catalog colors
`Ink`, `Paper` and `Card`, so screens never use raw colors. The source
drawing is `Design/golem.png`, and `Design/make-icons.sh` regenerates the
icon and in-app images from it. `Design/golem-eye.png` is the Dynamic Island
glyph, a single-colour template image.

Next direction (not started): lean further into the plea as a *manuscript
you write to the golem*, with a page-like plea screen and more of a letter
than a form, and reword the golem's lines in `GolemVoice` to match.

## 9. The golem wants to sleep; the limit is drastic (2026-11-01)

The character: scrolling wakes the golem and makes him watch over you. He
puts up with it within your limit (white eyes) and gets angry past it: red
eyes, a red timer counting past the limit, and "Plead with the Golem". All
wording lives in `GolemVoice`. The switch to red happens on its own at the
limit, because the limit is the Live Activity's *stale date* and iOS
redraws it then. iOS can't pop the Island open at that moment (that needs
the app's code running, or a server push). So the pop-up happens when you
reopen a group's app past its limit, which runs Golem's code via the
automation. The "time's up" notification stays for now, so the owner can
see how it feels; it may be removed.

## 10. Reliable timer: serial events, exact-group plea, locking (2026-11-01)

On the owner's iPhone the timer kept running after locking the phone inside
a watched app. iOS has no "phone locked" automation trigger. Locking doesn't
fire "Is Closed", and unlocking back into the app fires no "Is Opened".
GolemLite only runs code when an automation fires, so it can't notice
either. A Stop button on the Lock Screen timer was tried and removed: after
unlocking you were back in Instagram with no timer, which is worse. Now
locked time counts until you leave the app, and the guide says to go to the
Home Screen first. Golem stops every timer whenever it comes to the front,
because no watched app can be open then. Real screen-on time needs Screen
Time (the full flavour).

`SessionCoordinator` (now in GolemKit) handles events one after another.
Before, a quick open-and-close could finish the "closed" first, and the late
"opened" put the Island and a "time's up" notification back for a stopped
timer. Tapping a notification or the timer opens the plea for that exact
group (a `groupID` in the notification, `golem://plea/<id>` from the timer).
Otherwise Golem pleads for the group used most recently. Setup stays at two
automations per group (the owner's choice over one toggling automation).
`GolemShortcuts` lists Golem's actions in Shortcuts, and the guide is four
steps. A shared iCloud shortcut wouldn't save any steps, because each
automation still has to be made by hand.

## Open questions

- After **Close app** on the shield, the shield stays up until you plead or
  until midnight. Should it lift on its own after the break length, matching
  the timer's break reset?
- In GolemLite, nothing stops you once the time is up. Should the
  automation itself open Golem's plea screen (e.g. an "If over limit → Open
  Golem" step), instead of relying on the notification?
- Does restarting Screen Time monitoring really reset the count on a device?
  Verify once a paid account is available.
