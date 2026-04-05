import FamilyControls
import SwiftUI

/// Onboarding step for selecting managed apps.
/// Uses `.familyActivityPicker` modifier for full-screen system picker presentation.
struct AppSelectionStepView: View {

    @Bindable var selectionManager: AppSelectionManager

    @State private var showGeneralPicker = false
    @State private var showNovelPicker = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "apps.iphone")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("选择要管理的应用")
                .font(.title2.bold())

            Text("请分别为「通用组」和「小说组」各选择至少一个应用")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Selection buttons
            VStack(spacing: 12) {
                pickerButton(
                    label: "通用组",
                    icon: "apps.iphone",
                    count: generalCount,
                    selected: selectionManager.hasGeneralSelection,
                    action: { showGeneralPicker = true }
                )
                .familyActivityPicker(
                    headerText: "选择要管理的通用应用",
                    isPresented: $showGeneralPicker,
                    selection: $selectionManager.generalSelection
                )

                pickerButton(
                    label: "小说组",
                    icon: "book.fill",
                    count: novelCount,
                    selected: selectionManager.hasNovelSelection,
                    action: { showNovelPicker = true }
                )
                .familyActivityPicker(
                    headerText: "选择要管理的小说/阅读应用",
                    isPresented: $showNovelPicker,
                    selection: $selectionManager.novelSelection
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var generalCount: Int {
        selectionManager.generalSelection.applicationTokens.count
            + selectionManager.generalSelection.categoryTokens.count
    }

    private var novelCount: Int {
        selectionManager.novelSelection.applicationTokens.count
            + selectionManager.novelSelection.categoryTokens.count
    }

    private func pickerButton(
        label: String,
        icon: String,
        count: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(label)
                Spacer()
                if selected {
                    Text("已选 \(count) 项")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("未选择")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AppSelectionStepView(
        selectionManager: AppSelectionManager(sharedState: PreviewSharedState())
    )
}

private final class PreviewSharedState: KairosSharedStateProtocol {
    var authorizationGranted: Bool = false
    var generalSelection: FamilyActivitySelection? = nil
    var novelSelection: FamilyActivitySelection? = nil
    var onboardingCompleted: Bool = false
}
