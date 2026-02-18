import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var bodyWeight: Double
    var fitnessGoal: String
    @Attribute(.externalStorage) var profileImageData: Data?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        bodyWeight: Double = 0,
        fitnessGoal: String = "",
        profileImageData: Data? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.bodyWeight = bodyWeight
        self.fitnessGoal = fitnessGoal
        self.profileImageData = profileImageData
        self.updatedAt = updatedAt
    }
}
