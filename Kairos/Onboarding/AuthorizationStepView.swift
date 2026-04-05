import FamilyControls
import SwiftUI

/// Onboarding step that requests Screen Time authorization from the user.
struct AuthorizationStepView: View {

    @Bindable var authManager: AuthorizationManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            iconSection
            textSection
            statusIndicator
            requestButton
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Subviews

    private var iconSection: some View {
        Image(systemName: "lock.shield.fill")
            .font(.system(size: 80))
            .foregroundStyle(.blue)
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("需要屏幕时间权限")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Kairos 需要访问「屏幕使用时间」功能，才能帮助你管理应用使用，保护专注时间。\n\n我们不会收集你的任何个人数据。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            switch authManager.authorizationStatus {
            case .approved:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("已授权")
                    .foregroundStyle(.green)
            case .denied:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("授权被拒绝，请前往设置重新授权")
                    .foregroundStyle(.red)
            case .notDetermined:
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
                Text("尚未授权")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    private var requestButton: some View {
        Button {
            Task { await authManager.requestAuthorization() }
        } label: {
            Text("请求授权")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(authManager.authorizationStatus == .approved)
    }
}

// MARK: - Preview

#Preview {
    AuthorizationStepView(authManager: AuthorizationManager(sharedState: PreviewSharedState()))
}

// MARK: - PreviewSharedState

private final class PreviewSharedState: KairosSharedStateProtocol {
    var authorizationGranted: Bool = false
    var generalSelection: FamilyActivitySelection? = nil
    var novelSelection: FamilyActivitySelection? = nil
    var onboardingCompleted: Bool = false
}
