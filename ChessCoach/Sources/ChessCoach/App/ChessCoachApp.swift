import SwiftUI

@main
struct ChessCoachApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GameReviewScreen(
                    viewModel: GameReviewViewModel(game: SampleData.sampleGame)
                )
            }
        }
    }
}
