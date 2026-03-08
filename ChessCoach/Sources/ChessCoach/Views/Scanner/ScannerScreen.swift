import SwiftUI
#if canImport(VisionKit)
import VisionKit
#endif

/// Scoresheet Scanner — camera capture with full scan flow
struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDocumentCamera = false
    @State private var showPhotoPicker = false
    @State private var showProcessing = false
    @State private var showCorrection = false
    @State private var showMetadata = false
    @State private var showManualEntry = false
    @State private var scannedMoves: [ScannedMove] = []
    @State private var capturedImages: [CGImage] = []

    let knownTournaments: [String]
    /// Callback with validated SAN move strings and game metadata
    let onGameCreated: ([String], GameMetadata) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Scoresheet illustration
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 260)

                    VStack(spacing: 16) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.5))

                        Text("Scan your scoresheet")
                            .font(DesignSystem.Fonts.headline(18))

                        Text("Use the camera to capture your\nhandwritten chess notation")
                            .font(DesignSystem.Fonts.body(14))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
            }

            // Action buttons
            VStack(spacing: 12) {
                // Camera scan button
                Button {
                    showDocumentCamera = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                        Text("Scan with Camera")
                            .font(DesignSystem.Fonts.headline(17))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .fill(DesignSystem.Colors.primary)
                    )
                }
                .padding(.horizontal, 24)

                // Photo library button
                Button {
                    showPhotoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Choose from Photos")
                            .font(DesignSystem.Fonts.headline(17))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .strokeBorder(DesignSystem.Colors.primary, lineWidth: 2)
                    )
                }
                .padding(.horizontal, 24)
            }

            // Manual entry fallback
            Button {
                showManualEntry = true
            } label: {
                Text("Enter moves manually instead")
                    .font(DesignSystem.Fonts.body(15))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.top, 4)

            Spacer()
        }
        .navigationTitle("Scan Scoresheet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        // Document camera (iOS only)
        #if canImport(UIKit)
        .fullScreenCover(isPresented: $showDocumentCamera) {
            DocumentCameraView(
                onScan: { images in
                    showDocumentCamera = false
                    if !images.isEmpty {
                        capturedImages = images
                        showProcessing = true
                    }
                },
                onCancel: {
                    showDocumentCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(
                onPick: { image in
                    showPhotoPicker = false
                    capturedImages = [image]
                    showProcessing = true
                },
                onCancel: {
                    showPhotoPicker = false
                }
            )
        }
        #endif
        // Processing → Correction → Metadata flow
        .navigationDestination(isPresented: $showProcessing) {
            ProcessingScreen(images: capturedImages) { moves in
                scannedMoves = moves
                showProcessing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showCorrection = true
                }
            }
        }
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
