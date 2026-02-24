import SwiftUI

/// Scoresheet Scanner — placeholder for camera-based scoresheet capture
struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMetadata = false

    let knownTournaments: [String]
    let onGameCreated: (GameMetadata) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Camera placeholder
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 300)

                    VStack(spacing: 16) {
                        // Viewfinder icon
                        Image(systemName: "viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.4))

                        // Dashed guide rectangle
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.3))
                            .frame(width: 220, height: 160)
                            .overlay {
                                Text("Align your\nscoresheet\nwithin the frame")
                                    .font(DesignSystem.Fonts.body(14))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                    }
                }
                .padding(.horizontal, 24)

                Text("Camera capture coming soon!")
                    .font(DesignSystem.Fonts.coaching(15))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            // Capture controls
            HStack(spacing: 40) {
                // Flash
                Button {
                    // placeholder
                } label: {
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(width: DesignSystem.Layout.minTouchTarget,
                               height: DesignSystem.Layout.minTouchTarget)
                }

                // Capture button
                Button {
                    showMetadata = true
                } label: {
                    Circle()
                        .strokeBorder(DesignSystem.Colors.primary, lineWidth: 4)
                        .frame(width: 72, height: 72)
                        .overlay {
                            Circle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: 60, height: 60)
                        }
                }

                // Gallery
                Button {
                    showMetadata = true
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(width: DesignSystem.Layout.minTouchTarget,
                               height: DesignSystem.Layout.minTouchTarget)
                }
            }

            // Manual entry option
            Button {
                showMetadata = true
            } label: {
                Text("Enter moves manually")
                    .font(DesignSystem.Fonts.body(15))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.top, 8)

            Spacer()
        }
        .navigationTitle("Scan Scoresheet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .navigationDestination(isPresented: $showMetadata) {
            GameMetadataScreen(
                knownTournaments: knownTournaments,
                onSubmit: { metadata in
                    onGameCreated(metadata)
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        ScannerScreen(knownTournaments: ["Spring Open"]) { _ in }
    }
}
