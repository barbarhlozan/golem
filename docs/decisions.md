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
instead of iOS blue, a warm off-white "paper" background, serif system
type (New York, close to Times New Roman) for body text, and the blackletter UnifrakturMaguntia for big headings,
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

The plea screen is the one exception to the paper look; see 10.

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

## 11. First run, a calm home screen, and a separate debug menu (2026-11-01)

The home screen used to be one long form, with settings and debug buttons
in it. The owner wanted it to feel like a finished app with the golem in
it. Now:

- First launch shows four short pages: the golem, your groups and limits,
  notifications, and the automations. They appear once (`hasOnboarded` in
  UserDefaults) and share their steps with the setup guide.
- Home shows the golem and his mood: asleep with "z z z" while every group
  is within its limit, red and angry when one is over. Below are a red
  "Plead" card per over-limit group and a card per group showing how much
  of its limit is used. Breaks, plea rules, the guide and Screen Time
  blocking moved behind the gear (`SettingsView`).
- Debug builds have a ladybug menu (`DebugMenu`): simulate opening and
  closing apps, put a group over its limit, show the plea, send a
  "time's up" notification, reset the timers, replay the first run, and
  see the raw timer values. Release builds don't have it.

There is only one golem drawing, so his mood is shown by the line under him
and the colour. Sleeping and angry drawings can replace that later. The
home and first-run lines live in `GolemVoice+Home.swift`, apart from the
plea's wording.

## 12. The plea is a face-to-face with the golem, in the dark (2026-11-01)

The plea was a form on paper. Letter and manuscript versions (a ruled page
with "Dear Golem,", margin notes, a wax seal) were mocked up, but the owner
preferred something more direct. The plea is now a black full-screen cover.
The golem, drawn in white (the same drawing, colour-inverted), fades in and
grows slowly out of the dark. Above a plain text box he asks "Why must I
stay awake and guard you from the doom?". On the plea screen he speaks as
"I", and stays "he" everywhere else. His replies under the box count down
and ask for more ("I read slowly. 7s · 6 more letters").
"Let him sleep" is the big white button at the bottom, there from the
first moment, because letting him sleep and leaving is what Golem is for.
"Keep me up" is a quiet outline above it, lit only once the plea is met.

The waiting rule changed with it. The wait used to start when the screen
opened, so you could sit it out. It now starts at your first letter (10 s
by default, down from 30 s), next to the 20-character minimum. That way the
waiting is time spent explaining yourself. Settings saved on a device keep
their old wait until changed in Settings → Pleading.

The animation was tuned by the owner with sliders in a mockup. The numbers
live in `PleaGolemIntro.Tuning`, with distances as fractions of the screen
width. The text rises over a soft black fade, not a hard edge. With Reduce
Motion on, the screen appears without the animation. The drawing is blurry
this large; an upscaled version can simply replace the image.

## 13. The Island watches quietly, then keeps demanding an answer (2026-11-01)

The owner wanted the Island to stay small while you're within your limit
and, once you're past it, to grow and stay large, with the golem asking
why he's kept awake. iOS has no way to keep the Island expanded: it
expands on long-press, or for a few seconds when an update carries an
alert. Golem's code doesn't run while you scroll, and a server push isn't
possible on a free account. But iOS 26 lets an app book a Live Activity
to start later, with an alert. So:

- Opening an app within your limit shows the calm timer (white eyes,
  mm:ss counting up; long-press: group, time so far and a bar to the
  limit) and books red pop-ups for the limit.
- At the limit iOS starts them by itself and pops the Island open: red
  eyes, red timer, "Why are you keeping me awake?". Tapping it opens the
  plea. Closing the app cancels whatever is still booked.
- The owner wanted it annoying, so a pop-up comes every 10 s. iOS allows
  5 Live Activities per app, booked ones included: the timer plus 4
  pop-ups, so 40 s of demands. Reopening an app past the limit pops it
  open again and books 4 more. Only the newest shows in the Island.
- The default alert sound and buzz were too much every 10 s, so pop-ups
  use a soft double knock (`Golem/Resources/Sounds/golem-knock.caf`).
  iOS has no separate vibration setting for these alerts.

Verified in the iOS 26.2 Simulator. The "time's up" notification is
dropped on iOS 26+, because the pop-ups replace it; older iOS keeps it and
the plain stale-date switch to red. The Lock Screen keeps just a one-line
timer: you're rarely scrolling there.

The plea's "Let him sleep" button became "Sorry. Sleep well.", in the
golem's face-to-face voice.

The eyes can't loop an animation: a Live Activity is redrawn only when
its data changes, with at most a short transition, not frame by frame.

## 14. Resting gives time back, a second per second (2026-11-01)

Before, a group's used time stayed frozen while you were away and dropped
to zero only after a fixed break (10 min by default). Now the golem rests:
every second away gives a second back, so staying away as long as you were
in makes the group fresh again (pleaded bonus included). A first version
spread the time back over the fixed break, but then "fresh in" and the
used time counted down at different speeds, which read as a bug; with
one-to-one rest they're the same number. The break setting is gone. A
group that went over its limit can come back under it by resting. The
home screen refreshes every second and the group cards show "Resting"
while the time flows back. The rule is `GroupSession.rested(at:)`,
covered by unit tests.

## 15. In Golem, he's asleep, even past the limit (2026-11-01)

After "Sorry. Sleep well." the home screen said he was awake and angry,
and every return to Golem opened the plea again. But you've left the apps,
so he's resting, and the time is flowing back.

- The home screen shows him asleep. Only a Screen Time shield (full build)
  keeps him awake there.
- A group still past its limit gets a calm card, "Explain why you want to
  keep watching Reels". Tapping it wakes him for a plea.
- Opening Golem goes straight to the plea only when you've just left a
  group past its limit (within 10 s), or tapped the timer or a notification.

## 16. One timer stays alive, so opening an app doesn't drop the Island down (2026-11-02)

When the automation *starts* a Live Activity while you're in another app,
iOS shows it in its large form for a moment, dropping down over the screen.
Apps can't turn that off, and iOS sets that form's height: showing only
eyes and time in it (tried first) left it just as tall. An *update* without
an alert doesn't do that; the Island only widens to the sides.

So Golem keeps one timer alive between visits. Leaving the apps empties it
("away": nothing on either side of the camera, so the Island looks almost
as usual) instead of ending it, and opening one updates it. Only the first
visit, or one after iOS ended the timer (at most 8 hours), starts a new one
and still drops down once. The group is in the changing data now, so the
one timer can switch groups.

Costs: the empty timer stays on the Lock Screen ("The Golem is asleep."),
and the Island is a few points wider than normal while you're away. The
pop-ups past the limit stay large on purpose.

## 17. No pleading; you can talk to the golem instead (2026-11-02)

In use, the golem's presence did the job: the red, still-counting timer in
the Island kept the time in mind, while the plea (wait, write a reason,
"Keep me up 5 more minutes") added friction that didn't block anything. So
pleading, the plea rules and pleaded bonus time are gone. Past the limit
the Island stays red until the time flows back. While a group is over its
limit, a calm "Talk to the golem" card sits on the home screen, and tapping
the red Island, a "time's up" notification or the shield opens the same
conversation: the black, face-to-face screen, now as a chat. With Apple's
on-device model (FoundationModels, iOS 26+, Apple Intelligence on) he
really answers, in character, from `GolemVoice.talkInstructions`; nothing
leaves the phone. Without it he replies with hand-written lines
(`GolemVoice.talkFallbackReplies`). Nothing opens by itself any more. In
the full build the shield now only lifts at midnight or when blocking is
stopped (an open question below).

## 18. The timer ends when you leave, after all (2026-11-02)

Reverses decision 16. Keeping one empty timer alive between visits did stop
the Island from dropping down on each visit, but the golem then stayed on
the Lock Screen all day ("The Golem is asleep.") and felt like he was
running in the background, which the owner didn't want. iOS gives no way
to have both: a running Live Activity always shows on the Lock Screen, and
Golem's code doesn't run later to end it. So leaving a group's apps ends
the timer again, along with any pop-ups booked for the limit, and each new
visit's timer drops down large for a moment before settling into the slim
line. Switching between a group's apps still keeps and updates one timer.

## 19. No chat; the golem speaks in stages, with AI-written lines (2026-11-02)

The chat with the golem (decision 17) didn't serve a purpose in use, so it's
gone, along with its home card, `golem://talk` links and the shield's
"Talk to the golem" button. Instead the golem speaks up in the Island in
stages, each popping it open (an alert) with a new line: waking (white) as
the timer starts, stirring (orange) at 80% of the limit, angry (red) at the
limit and at +1 and +2 minutes. They're separate Live Activities booked to
start by themselves (iOS 26+); 5 is iOS's cap, so the timer, one orange and
three red. The pop-up only stays large for a few seconds; no app can keep
it expanded.

His lines are written ahead by Apple's on-device model (`LineWriter`) in
two batches per moment (`LineBook`): pop-ups take from the current batch,
so they're instant; at 80% used the spare takes over and a new one is
written whenever Golem's code next runs (after each app open/close, or with
Golem open). Hand-written lines fill in until then, and on phones without
Apple Intelligence.

## 20. Home: the golem in his dungeon, a ledger of groups (2026-11-02)

The owner wanted home "more polished, and purposeful". Of three sketches
(tidy, ledger, golem first) they picked a mix of golem first and ledger.

- Home is black in both modes (`Theme.night`), as if he slept in a
  dungeon; the cream paper stays for the other screens, though screens
  pushed from home are shown in dark mode so they don't flash back to it.
- A big blackletter "Golem" title, the golem big, and two lines in a grave
  voice for an old, majestic creature (not a napping baby): "The Golem
  sleeps. / Do not wake him.", "The Golem settles. / Feeds: 4:55 until he
  sleeps", "The Golem rumbles. / Reels: 0:33 until he quiets". The small
  line is always one line, so the rows below never jump.
- The colour follows the Island's stages for the group that worries him
  most (`GolemMoment(usedSeconds:limitSeconds:)`): what you'd walk back
  into now. White, orange from 80%, red past the limit, with faint
  torchlight behind him; it steps down as the time flows back. The golem
  himself stays white: tinting the drawing read like a filter.
- Groups are ruled rows, not cards: name, limit, status ("Resting, 1:15 to
  go") and today's visits and the longest one (`DayLog`, reset at
  midnight). No progress bars, here or in the Island: the time says it.
- Only the gear stays in the toolbar; the debug menu moved to Settings.
- Until an app has been seen opening, he points to the automations.
- Moving the drawing in code (breathing, a shudder, a drifting "z") was
  tried and dropped: it broke the hand-drawn look. Each phase will get
  the owner's own short animation instead.

## 21. The golem moves in the owner's own frames (2026-11-02)

Moving the drawing in code broke the hand-drawn look (entry 20), so the
owner drew short loops instead, and code only picks which frame to show.

- A five-frame loop per state, at 12 fps: asleep (eyes closed), settling
  (half-open) and restless (wide open; keeping watch uses it too). The
  lines are redrawn every frame, so he "boils" gently even when still.
- Between states his eyes open or close through five wake-up frames. Each
  loop shares a frame with them, and a loop only lets go at that frame, so
  nothing cuts (`GolemReel`, tested in GolemKit). The last wake-up frame
  is never shown: the restless loop stands in for it.
- Coming straight from a watched app (Golem stopped a running timer), he's
  shown wide awake for one loop, then settles into his state.
- Sparks rise beside him while he's red (6) or orange (3): copies of three
  hand-drawn embers, each flying up through its own tile, at random spots
  behind him. The torchlight glow from entry 20 was dropped: the sparks
  say it.
- He's 30% smaller (182 pt), so the sparks have room.
- The drawings are kept as drawn in `Design/frames`;
  `Design/make-frames.sh` cuts them out onto one shared box, so he never
  jumps. Reduce Motion holds a still frame, without sparks.

## Open questions

- Does iOS let the on-device model write lines in the background (during
  the automations)? If not, the batches only refill while Golem is open.

- Full build: without pleading, a group's Screen Time shield stays up until
  midnight (or until blocking is stopped). Should it lift on its own once
  the group has rested back under its limit, matching the one-to-one rest?
- Does restarting Screen Time monitoring really reset the count on a device?
  Verify once a paid account is available.
- With a paid account, should the golem keep demanding an answer past the
  limit for as long as you scroll? Now he stops after 4 pop-ups (40 s),
  because an app may hold only 5 Live Activities, until you reopen the app.
  Push updates from a server (paid account) could pop the Island open every
  10 s for as long as needed.
