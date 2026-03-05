import SwiftUI

/// Scoresheet Scanner — camera capture with full scan flow
struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showProcessing = false
    @State private var showCorrection = false
    @State private var showMetadata = false
    @State private var showManualEntry = false
    @State private var scannedMoves: [ScannedMove] = []

    let knownTournaments: [String]
    /// Callback with validated SAN move strings and game metadata
    let onGameCreated: ([String], GameMetadata) -> Void

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
                        Image(systemName: "viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.4))

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

                Text("Tap the shutter to scan a scoresheet")
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

                // Capture button — triggers scan flow
                Button {
                    showProcessing = true
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
                    showProcessing = true
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(width: DesignSystem.Layout.minTouchTarget,
                               height: DesignSystem.Layout.minTouchTarget)
                }
            }

            // Manual entry — type moves from a paper scoresheet
            Button {
                showManualEntry = true
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
        // Flow A: Scanner → Processing → Correction → Metadata
        .navigationDestination(isPresented: $showProcessing) {
            ProcessingScreen { moves in
                scannedMoves = moves
                showProcessing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showCorrection = true
                }
            }
        }
        // Flow B: Manual Entry → Correction → Metadata
        .navigationDestination(isPresented: $showManualEntry) {
            ManualMoveEntryScreen { moves in
                scannedMoves = moves
                showManualEntry = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showCorrection = true
                }
            }
        }
        .navigationDestination(isPresented: $showCorrection) {
            MoveCorrectionScreen(
                viewModel: MoveCorrectionViewModel(scannedMoves: scannedMoves)
            ) { correctedMoves in
                scannedMoves = correctedMoves
                showCorrection = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showMetadata = true
                }
            }
        }
        .navigationDestination(isPresented: $showMetadata) {
            GameMetadataScreen(
                knownTournaments: knownTournaments,
                onSubmit: { metadata in
                    let sanMoves = scannedMoves.map { $0.san }
                    onGameCreated(sanMoves, metadata)
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        ScannerScreen(knownTournaments: ["Spring Open"]) { _, _ in }
    }
}
