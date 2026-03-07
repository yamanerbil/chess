import SwiftUI
import SwiftData

/// App entry point
#if !SPM_BUILD
@main
#endif
struct ChessCoachApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [GameRecord.self, PlayerProfile.self])
    }
}

/// Root tab navigation for the app
public struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameRecord.createdAt, order: .reverse) private var gameRecords: [GameRecord]
    @State private var selectedTab = 0
    @State private var showScanner = false

    public init() {}

    private var games: [Game] {
        gameRecords.compactMap { $0.toGame() }
    }

    private var tournaments: [String] {
        let events = games.compactMap { $0.event }
        return Array(Set(events)).sorted()
    }

    public var body: some View {
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
            .overlay(alignment: .bottom) {
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
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                ScannerScreen(knownTournaments: tournaments) { sanMoves, metadata in
                    saveGame(sanMoves: sanMoves, metadata: metadata)
                    showScanner = false
                }
            }
        }
        .onAppear {
            seedSampleDataIfEmpty()
        }
    }

    private func saveGame(sanMoves: [String], metadata: GameMetadata) {
        guard let game = Game.fromSANList(sanMoves: sanMoves, metadata: metadata) else { return }
        let record = GameRecord(game: game)
        modelContext.insert(record)
        try? modelContext.save()
    }

    private func seedSampleDataIfEmpty() {
        guard gameRecords.isEmpty else { return }
        for game in SampleData.allGames {
            let record = GameRecord(game: game)
            modelContext.insert(record)
        }
        try? modelContext.save()
    }
}

#Preview("Main App") {
    MainTabView()
        .modelContainer(for: [GameRecord.self, PlayerProfile.self], inMemory: true)
}

#Preview("Game Review") {
    NavigationStack {
        GameReviewScreen(viewModel: GameReviewViewModel(game: SampleData.sampleGame))
    }
}
