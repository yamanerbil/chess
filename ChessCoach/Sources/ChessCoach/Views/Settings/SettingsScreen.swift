import SwiftUI

/// Settings screen — app preferences
struct SettingsScreen: View {
    @State private var showBegPieces = false
    @State private var hapticEnabled = true
    @State private var boardTheme = 0 // 0 = classic, 1 = blue, 2 = green

    var body: some View {
        List {
            Section("Board") {
                Toggle("Beginner pieces (with letters)", isOn: $showBegPieces)
                Toggle("Haptic feedback on moves", isOn: $hapticEnabled)
                Picker("Board theme", selection: $boardTheme) {
                    Text("Classic").tag(0)
                    Text("Blue").tag(1)
                    Text("Green").tag(2)
                }
            }

            Section("Analysis") {
                HStack {
                    Text("Engine")
                    Spacer()
                    Text("Stockfish (on-device)")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                Link("Privacy Policy", destination: URL(string: "https://example.com")!)
                Link("Terms of Service", destination: URL(string: "https://example.com")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
