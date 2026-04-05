import SwiftUI
import KairosKit

// MARK: - ModeCardView

/// Large, prominent card displaying the current Kairos mode and its status.
struct ModeCardView: View {

    let mode: KairosMode
    let statusMessage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: mode.iconName)
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(iconColor)

            Text(mode.displayName)
                .font(.title.bold())
                .foregroundStyle(.primary)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Colors

    private var iconColor: Color {
        switch mode {
        case .morning: .orange
        case .normal: .yellow
        case .night: .indigo
        }
    }

    private var cardBackground: some ShapeStyle {
        switch mode {
        case .morning:
            AnyShapeStyle(
                LinearGradient(
                    colors: [.orange.opacity(0.15), .yellow.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .normal:
            AnyShapeStyle(
                LinearGradient(
                    colors: [.yellow.opacity(0.12), .green.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .night:
            AnyShapeStyle(
                LinearGradient(
                    colors: [.indigo.opacity(0.18), .blue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Preview

#Preview("Morning") {
    ModeCardView(mode: .morning, statusMessage: "早晨模式 · 即将可用")
        .padding()
}

#Preview("All Modes") {
    ScrollView {
        VStack(spacing: 16) {
            ModeCardView(mode: .morning, statusMessage: "早晨模式 · 30分钟后可用")
            ModeCardView(mode: .normal, statusMessage: "普通模式 · 正常使用中")
            ModeCardView(mode: .night, statusMessage: "晚间模式 · 额度使用中")
        }
        .padding()
    }
}
