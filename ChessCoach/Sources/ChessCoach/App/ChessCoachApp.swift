import SwiftUI

/// App entry point — uncomment @main when building as an app target
// @main
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
