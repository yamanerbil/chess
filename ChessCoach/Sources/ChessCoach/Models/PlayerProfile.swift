import Foundation
import SwiftData

/// SwiftData model for persisting the player's profile information.
@Model
final class PlayerProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var rating: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        rating: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
