import Foundation
import SwiftData

@MainActor
final class ProfileRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadOrCreateProfile() throws -> UserProfile {
        let interval = SignpostInterval(name: "SwiftDataFetch", message: "profile")
        defer { interval.end(message: "completed") }

        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\UserProfile.updatedAt, order: .reverse)])
        if let profile = try context.fetch(descriptor).first {
            return profile
        }

        let profile = UserProfile()
        context.insert(profile)
        try context.save()
        return profile
    }

    func save(profile: UserProfile) throws {
        profile.updatedAt = .now
        try context.save()
    }
}
