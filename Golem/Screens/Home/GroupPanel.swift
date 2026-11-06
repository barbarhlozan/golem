import FamilyControls
import GolemKit
import SwiftUI

/// What a group's chip opens: everything about the group in one short
/// list, so there's no separate screen to go to. Its name, its limit, its
/// apps (with Screen Time) and, last, deleting it.
///
/// Deleting asks first: the group's two automations in Shortcuts stay
/// behind and have to be removed by hand, and the dialog says so.
struct GroupPanel: View {
    @Binding var group: WatchGroup
    let delete: () -> Void

    @State private var isPickingApps = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The pencil says the name can be typed over.
            HStack {
                TextField(GolemVoice.groupNamePlaceholder, text: $group.name)
                    .submitLabel(.done)
                Image(systemName: "pencil")
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)

            Divider()

            Stepper(
                GolemVoice.groupLimitStepper(minutes: group.limitMinutes),
                value: $group.limitMinutes,
                in: WatchGroup.allowedLimitMinutes
            )
            .padding(.vertical, 8)

            if Capabilities.screenTime {
                Divider()
                Button(appsLabel) { isPickingApps = true }
                    .padding(.vertical, 12)
            }

            Divider()

            Button(GolemVoice.groupDeleteButton, role: .destructive) { isConfirmingDelete = true }
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.ink.opacity(0.15), lineWidth: 0.5)
        )
        .familyActivityPicker(isPresented: $isPickingApps, selection: $group.appSelection)
        .confirmationDialog(
            GolemVoice.groupDeleteTitle(name: group.name),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(GolemVoice.groupDeleteButton, role: .destructive, action: delete)
        } message: {
            Text(GolemVoice.groupDeleteHint)
        }
    }

    private var appsLabel: String {
        let count = group.appSelection.applicationTokens.count
            + group.appSelection.categoryTokens.count
            + group.appSelection.webDomainTokens.count
        return GolemVoice.groupAppsButton(count: count)
    }
}
