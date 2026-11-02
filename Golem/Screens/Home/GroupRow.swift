import GolemKit
import SwiftUI

/// One group in the home screen's ledger: its name and limit, how it
/// stands now (fresh, or resting, in the Island's colour), and today's
/// visits. No bar: the time to go says the same, and less ink is calmer.
struct GroupRow: View {
    let group: WatchGroup
    let usedSeconds: TimeInterval
    let isOverLimit: Bool
    let today: DayLog.Entry

    private var limitSeconds: TimeInterval { TimeInterval(group.limitMinutes * 60) }
    private var isResting: Bool { usedSeconds >= 1 }

    /// What the Island would show if you went back now.
    private var moment: GolemMoment {
        isOverLimit ? .angry : GolemMoment(usedSeconds: usedSeconds, limitSeconds: limitSeconds)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(group.name)
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Text(GolemVoice.groupLimit(minutes: group.limitMinutes))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(status)
                    .font(.subheadline.monospacedDigit())
                    .lineLimit(1)
                    .foregroundStyle(Theme.color(for: moment))

                Text(GolemVoice.groupToday(visits: today.visits, longest: today.longestSeconds.minutesSeconds))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private var status: String {
        guard isResting else { return GolemVoice.groupFresh }
        let time = usedSeconds.minutesSeconds
        return isOverLimit ? GolemVoice.groupOverLimit(time: time) : GolemVoice.groupResting(time: time)
    }
}
