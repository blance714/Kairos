import SwiftUI

// MARK: - SleepFocusGuideView

/// Explains to the user how to connect Kairos to the system Sleep Focus.
///
/// Navigation path: Settings → Focus → Sleep → Apps → Add Filter → Kairos
struct SleepFocusGuideView: View {

    // MARK: - Steps

    private struct Step: Identifiable {
        let id: Int
        let icon: String
        let text: LocalizedStringKey
    }

    private let steps: [Step] = [
        Step(id: 1, icon: "gear",           text: "打开「设置」"),
        Step(id: 2, icon: "moon.fill",      text: "选择「专注模式」→「睡眠」"),
        Step(id: 3, icon: "slider.horizontal.3", text: "向下滚动到「过滤器」"),
        Step(id: 4, icon: "plus.circle.fill", text: "点击「添加过滤器」"),
        Step(id: 5, icon: "app.badge.fill",  text: "选择「Kairos」"),
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                stepsSection
                openSettingsButton
            }
            .padding(24)
        }
        .navigationTitle("设置睡眠专注过滤器")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("连接睡眠专注模式", systemImage: "moon.zzz.fill")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("将 Kairos 作为过滤器添加到系统「睡眠专注模式」后，每次开启 / 关闭睡眠模式，Kairos 都会自动调整应用管控策略。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("操作步骤")
                .font(.headline)

            ForEach(steps) { step in
                stepRow(step)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func stepRow(_ step: Step) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: step.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("第 \(step.id) 步")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(step.text)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)
        }
    }

    private var openSettingsButton: some View {
        Button {
            openSettings()
        } label: {
            Label("前往「设置」", systemImage: "arrow.up.right.square")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // MARK: - Actions

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SleepFocusGuideView()
    }
}
