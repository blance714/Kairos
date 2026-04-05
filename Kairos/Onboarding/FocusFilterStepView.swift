import SwiftUI

/// Onboarding step that wraps the SleepFocusGuideView.
struct FocusFilterStepView: View {

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            SleepFocusGuideView()
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo)
            Text("连接睡眠专注模式（可选）")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("按照以下步骤将 Kairos 添加为睡眠专注过滤器，实现自动夜间管控。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Preview

#Preview {
    FocusFilterStepView()
}
