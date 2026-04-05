import SwiftUI
import KairosKit

// MARK: - DashboardView

/// Root dashboard screen showing the current Kairos mode and key status information.
struct DashboardView: View {

    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ModeCardView(
                        mode: viewModel.currentMode,
                        statusMessage: viewModel.statusMessage
                    )
                    .padding(.horizontal)

                    if !viewModel.nextChangeDescription.isEmpty {
                        NextChangeView(description: viewModel.nextChangeDescription)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Kairos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                viewModel.refresh()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
