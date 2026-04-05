import SwiftUI

/// First onboarding step — introduces the app and its purpose.
struct WelcomeStepView: View {

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            iconSection
            textSection
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Subviews

    private var iconSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            Image(systemName: "hourglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.white)
        }
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("欢迎使用 Kairos")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("智能管理你的屏幕时间")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Kairos 帮助你合理控制手机应用的使用时长，让你在恰当的时间专注于更重要的事情。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeStepView()
}
