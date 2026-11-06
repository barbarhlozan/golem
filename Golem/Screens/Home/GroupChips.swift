import GolemKit
import SwiftUI

/// The groups as small chips under the golem, like "Reels · 5m". A chip
/// turns orange or red, with the time to go, while its group rests.
/// Tapping one opens its settings below (`GroupPanel`); tapping it again
/// closes them.
///
/// The chips float in out of the dark when the screen first appears, one
/// after another, and then hover gently, like the app bubbles on an Apple
/// Watch. Both are skipped with Reduce Motion.
struct GroupChips: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// False until the screen's entrance plays; the chips follow the golem.
    let isShown: Bool

    @State private var openID: UUID?

    var body: some View {
        VStack(spacing: 14) {
            ChipFlow(spacing: 8) {
                ForEach(Array(model.settings.groups.enumerated()), id: \.element.id) { index, group in
                    Chip(
                        text: text(for: group),
                        color: color(for: group),
                        isOpen: openID == group.id
                    ) {
                        withAnimation(.snappy) { openID = openID == group.id ? nil : group.id }
                    }
                    .floating(index: index, isShown: isShown, reduceMotion: reduceMotion)
                }
            }

            if let id = openID, let group = model.settings.groups.first(where: { $0.id == id }) {
                GroupPanel(
                    group: binding(for: group),
                    delete: { delete(id) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Looked up by id on every read and write, so the panel never holds
    /// on to a position in the list that a deletion has moved.
    private func binding(for group: WatchGroup) -> Binding<WatchGroup> {
        Binding(
            get: { model.settings.groups.first { $0.id == group.id } ?? group },
            set: { new in
                guard let index = model.settings.groups.firstIndex(where: { $0.id == group.id }) else { return }
                model.settings.groups[index] = new
            }
        )
    }

    /// Closes the panel first and removes the group once it has faded out.
    private func delete(_ id: UUID) {
        withAnimation(.snappy) { openID = nil }
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.snappy) { model.deleteGroup(id: id) }
        }
    }

    private func text(for group: WatchGroup) -> String {
        let used = model.usedSeconds(of: group)
        guard used >= 1 else {
            return GolemVoice.groupChip(name: group.name, limitMinutes: group.limitMinutes)
        }
        return GolemVoice.groupChipResting(name: group.name, time: used.minutesSeconds)
    }

    /// The Island's colour for the group while it rests; ink when fresh.
    private func color(for group: WatchGroup) -> Color {
        let used = model.usedSeconds(of: group)
        guard used >= 1 else { return Theme.ink }
        let moment = model.isOverLimit(group)
            ? GolemMoment.angry
            : GolemMoment(usedSeconds: used, limitSeconds: TimeInterval(group.limitMinutes * 60))
        return moment == .waking ? Theme.ink : Theme.color(for: moment)
    }
}

/// One chip: a hairline capsule, filled faintly while its panel is open.
private struct Chip: View {
    let text: String
    let color: Color
    let isOpen: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            Text(text)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(color.opacity(isOpen ? 0.18 : 0)))
                .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 0.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    /// Rises out of the dark (from small, faint and blurred) a moment after
    /// the golem, one chip after another, then hovers gently up and down,
    /// each chip at its own pace.
    func floating(index: Int, isShown: Bool, reduceMotion: Bool) -> some View {
        modifier(Floating(index: index, isShown: isShown, reduceMotion: reduceMotion))
    }
}

private struct Floating: ViewModifier {
    let index: Int
    let isShown: Bool
    let reduceMotion: Bool

    @State private var isUp = false

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .scaleEffect(isShown || reduceMotion ? 1 : 0.6)
            .blur(radius: isShown || reduceMotion ? 0 : 6)
            .offset(y: isShown || reduceMotion ? 0 : 14)
            .animation(
                .spring(response: 0.7, dampingFraction: 0.7).delay(0.7 + Double(index) * 0.12),
                value: isShown
            )
            .offset(y: reduceMotion ? 0 : (isUp ? -2.5 : 2.5))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 2.4 + Double(index % 3) * 0.4).repeatForever(autoreverses: true),
                value: isUp
            )
            .onAppear {
                guard !reduceMotion else { return }
                // Start each chip's hover a little later, so they drift
                // out of step with each other.
                Task {
                    try? await Task.sleep(for: .seconds(1.4 + Double(index) * 0.3))
                    isUp = true
                }
            }
    }
}

/// Chips side by side, wrapping onto the next line, each line centred.
private struct ChipFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews: subviews) {
            var x = bounds.midX - row.width / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
