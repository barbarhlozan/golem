# Golem: notes for AI assistants

iOS anti-doomscrolling app (SwiftUI, Swift 6, Shortcuts + Live Activities +
Screen Time). Read `README.md` and `docs/architecture.md` first.

- The Xcode project is generated: edit `project.yml`, then run `xcodegen`.
  Never edit or commit `Golem.xcodeproj` or `Generated/`.
- Two app flavours share `Golem/`: `Golem` (Screen Time, needs a paid account)
  and `GolemLite` (no Screen Time). Guard Screen Time-only behaviour with
  `Capabilities.screenTime`.
- Build check (no signing needed):
  `xcodebuild -project Golem.xcodeproj -scheme GolemLite -destination 'generic/platform=iOS Simulator' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
  (do the same with `-scheme Golem`).
- Logic tests: `cd Packages/GolemKit && swift test`
- Put shared logic in `GolemKit`, and keep it free of iOS-only frameworks
  where possible so it stays testable on macOS. Guard ActivityKit and
  Screen Time code with `#if os(iOS)`.
- All user-facing text goes in `GolemVoice`.
- Keep files small and single-purpose, with a doc comment that explains *why*.
  The owner wants the code easy to read and edit.
- Record notable design decisions in `docs/decisions.md`.
- The owner has a free Apple account: `GolemLite` installs on their iPhone,
  the full `Golem` doesn't sign.
