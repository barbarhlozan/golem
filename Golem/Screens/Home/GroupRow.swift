import GolemKit
import SwiftUI

/// One group in the home screen's ledger: its name, its limit and the
/// arrow on one line, and, only while the golem is resting, how long that
/// takes, in the Island's colour. No bar and no history: the less ink, the
/// calmer.
struct GroupRow: View {
    let group: WatchGroup
    let usedSeconds: TimeInterval
    let isOverLimit: Bool

    private var limitSeconds: TimeInterval { TimeInterval(group.limitMinutes * 60) }
    private var isResting: Bool { usedSeconds >= 1 }

    /// What the Island would show if you went back now.
    private var moment: GolemMoment {
        isOverLimit ? .angry : GolemMoment(usedSeconds: usedSeconds, limitSeconds: limitSeconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(group.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(GolemVoice.groupLimit(minutes: group.limitMinutes))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            if isResting {
                Text(status)
                    .font(.subheadline.monospacedDigit())
                    .lineLimit(1)
                    .foregroundStyle(Theme.color(for: moment))
            }
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private var status: String {
        let time = usedSeconds.minutesSeconds
        return isOverLimit ? GolemVoice.groupOverLimit(time: time) : GolemVoice.groupResting(time: time)
    }
}
