# Golem: notes for AI assistants

iOS anti-doomscrolling app (SwiftUI, Screen Time APIs). Read `README.md` and
`docs/architecture.md` first.

- The Xcode project is generated: edit `project.yml`, then run `xcodegen`.
  Never edit or commit `Golem.xcodeproj`, the Info.plists or the entitlements.
- Build check (no signing needed):
  `xcodebuild -project Golem.xcodeproj -scheme Golem -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
- Logic tests: `cd Packages/GolemKit && swift test`
- Put shared logic in `GolemKit`, and keep it free of Screen Time imports where
  possible so it stays testable on macOS. Guard Screen Time code with `#if os(iOS)`.
- All user-facing text goes in `GolemVoice`.
- Keep files small and single-purpose, with a doc comment that explains *why*.
  The owner wants the code easy to read and edit.
- Record notable design decisions in `docs/decisions.md`.
- The owner has a free Apple account for now, so Screen Time features can't be
  tested on device yet.
