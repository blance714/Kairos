import FamilyControls
import SwiftUI

/// View for selecting which apps belong to the General and Novel groups.
/// Uses `.familyActivityPicker(isPresented:selection:)` modifier for reliable system presentation.
struct AppSelectionView: View {

    @Bindable var selectionManager: AppSelectionManager

    @State private var showGeneralPicker = false
    @State private var showNovelPicker = false
    @State private var showSaveConfirmation = false

    var body: some View {
        Form {
            generalSection
            novelSection
            saveSection
        }
        .navigationTitle("应用选择")
    }

    // MARK: - Sections

    private var generalSection: some View {
        Section {
            Button(action: { showGeneralPicker = true }) {
                HStack {
                    Label("选择通用应用", systemImage: "apps.iphone")
                    Spacer()
                    Text("\(generalSelectionCount) 个项目")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .familyActivityPicker(
                headerText: "选择要管理的通用应用（如小红书、微博、B站等）",
                footerText: "已选择 \(generalSelectionCount) 个项目",
                isPresented: $showGeneralPicker,
                selection: $selectionManager.generalSelection
            )
        } header: {
            Label("通用组", systemImage: "apps.iphone")
        }
    }

    private var novelSection: some View {
        Section {
            Button(action: { showNovelPicker = true }) {
                HStack {
                    Label("选择小说/阅读应用", systemImage: "book.fill")
                    Spacer()
                    Text("\(novelSelectionCount) 个项目")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .familyActivityPicker(
                headerText: "选择要管理的小说/阅读应用",
                footerText: "已选择 \(novelSelectionCount) 个项目",
                isPresented: $showNovelPicker,
                selection: $selectionManager.novelSelection
            )
        } header: {
            Label("小说组", systemImage: "book.fill")
        }
    }

    private var saveSection: some View {
        Section {
            Button(action: save) {
                HStack {
                    Spacer()
                    Text("保存选择")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!selectionManager.hasBothSelections)
        } footer: {
            if !selectionManager.hasBothSelections {
                Text("请在两个分组中各选择至少一个应用")
                    .foregroundStyle(.secondary)
            }
            if showSaveConfirmation {
                Text("已保存")
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Helpers

    private var generalSelectionCount: Int {
        selectionManager.generalSelection.applicationTokens.count
            + selectionManager.generalSelection.categoryTokens.count
            + selectionManager.generalSelection.webDomainTokens.count
    }

    private var novelSelectionCount: Int {
        selectionManager.novelSelection.applicationTokens.count
            + selectionManager.novelSelection.categoryTokens.count
            + selectionManager.novelSelection.webDomainTokens.count
    }

    private func save() {
        selectionManager.saveSelections()
        showSaveConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showSaveConfirmation = false
        }
    }
}

#Preview {
    NavigationStack {
        AppSelectionView(selectionManager: AppSelectionManager())
    }
}
