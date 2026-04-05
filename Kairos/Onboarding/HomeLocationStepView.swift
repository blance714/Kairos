import SwiftUI

/// Onboarding step that wraps HomeLocationView with an optional skip affordance.
struct HomeLocationStepView: View {

    let geofenceManager: GeofenceManager
    var onSkip: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            skipBanner
            HomeLocationView(manager: geofenceManager)
        }
    }

    // MARK: - Subviews

    private var skipBanner: some View {
        VStack(spacing: 4) {
            Text("设置家庭位置（可选）")
                .font(.headline)
            Text("设置后，Kairos 将在你回家时自动调整管控策略。你也可以跳过此步骤稍后设置。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            if let onSkip {
                Button("跳过此步骤", action: onSkip)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.regularMaterial)
    }
}

// MARK: - Preview

#Preview {
    HomeLocationStepView(
        geofenceManager: GeofenceManager(),
        onSkip: {}
    )
}
