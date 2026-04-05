import SwiftUI

// MARK: - SettingsView

/// Application settings screen.
struct SettingsView: View {

    var body: some View {
        Form {
            appManagementSection
            locationSection
            focusModeSection
            aboutSection
        }
        .navigationTitle("设置")
    }

    // MARK: - Sections

    private var appManagementSection: some View {
        Section("应用管理") {
            NavigationLink("管控应用选择") {
                AppSelectionView(selectionManager: AppSelectionManager())
            }
        }
    }

    private var locationSection: some View {
        Section("位置") {
            NavigationLink("家的位置") {
                HomeLocationView(manager: GeofenceManager())
            }
        }
    }

    private var focusModeSection: some View {
        Section("专注模式") {
            NavigationLink("睡眠专注模式设置") {
                SleepFocusGuideView()
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("版本")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
