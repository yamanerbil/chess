import SwiftUI

/// App entry point
#if !SPM_BUILD
@main
#endif
struct ChessCoachApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

/// Root tab navigation for the app
public struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var games: [Game] = SampleData.allGames
    @State private var showScanner = false

    public init() {}

    private var tournaments: [String] {
        let events = games.compactMap { $0.event }
        return Array(Set(events)).sorted()
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Home tab
                NavigationStack {
                    HomeScreen(games: games)
                        .navigationDestination(for: UUID.self) { gameId in
                            if let game = games.first(where: { $0.id == gameId }) {
                                GameReviewScreen(viewModel: GameReviewViewModel(game: game))
                            }
                        }
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

                // Progress tab
                NavigationStack {
                    ProgressScreen(games: games)
                }
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

                // Settings tab
                NavigationStack {
                    SettingsScreen()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
            }

            // Floating Scan Game button (visible on Home tab)
            if selectedTab == 0 {
                Button {
                    showScanner = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Scan Game")
                            .font(DesignSystem.Fonts.headline(16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.primary)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                ScannerScreen(knownTournaments: tournaments) { _ in
                    // When scanner is fully implemented, this will create a real game.
                    // For now just dismiss.
                    showScanner = false
                }
            }
        }
    }
}

#Preview("Main App") {
    MainTabView()
}

#Preview("Game Review") {
    NavigationStack {
        GameReviewScreen(viewModel: GameReviewViewModel(game: SampleData.sampleGame))
    }
}
