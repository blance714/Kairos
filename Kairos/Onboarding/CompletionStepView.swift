import SwiftUI

/// Final onboarding step — confirms setup is complete and lets the user enter the app.
struct CompletionStepView: View {

    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            iconSection
            textSection
            Spacer()
            finishButton
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    // MARK: - Subviews

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.green.opacity(0.8), .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("设置完成！")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Kairos 已准备就绪，将帮助你科学管理屏幕时间，保持专注与平衡。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var finishButton: some View {
        Button(action: onFinish) {
            Text("开始使用")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

// MARK: - Preview

#Preview {
    CompletionStepView(onFinish: {})
}
