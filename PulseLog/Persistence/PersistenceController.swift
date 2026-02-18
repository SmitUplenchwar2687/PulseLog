import Foundation
import SwiftData

enum PersistenceError: Error {
    case profileNotFound
}

final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            WorkoutLog.self,
            UserProfile.self
        ])

        let configuration = ModelConfiguration("PulseLog")

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // App cannot function without persistence; surface a clear programming-time failure.
            preconditionFailure("Failed to initialize SwiftData container: \(error)")
        }
    }
}
