import SwiftUI

// MARK: - NextChangeView

/// Small info row that tells the user when the next mode transition will occur.
struct NextChangeView: View {

    let description: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        NextChangeView(description: "30分钟后可用")
        NextChangeView(description: "即将可用")
        NextChangeView(description: "明天见")
    }
    .padding()
}
