import Foundation
import SwiftData
import UIKit

@MainActor
final class ProfileViewModel: TrackedViewModel {
    @Published var name = ""
    @Published var bodyWeight = ""
    @Published var fitnessGoal = ""
    @Published private(set) var profileImage: UIImage?
    @Published var errorMessage: String?
    @Published private(set) var isSaving = false

    private var repository: ProfileRepository?
    private var profile: UserProfile?

    init() {
        super.init(typeName: String(describing: ProfileViewModel.self))
    }

    func configure(context: ModelContext) {
        guard repository == nil else { return }
        repository = ProfileRepository(context: context)

        Task {
            await loadProfile()
        }
    }

    func loadProfile() async {
        guard let repository else { return }

        do {
            let profile = try repository.loadOrCreateProfile()
            self.profile = profile
            name = profile.name
            bodyWeight = profile.bodyWeight == 0 ? "" : String(format: "%.1f", profile.bodyWeight)
            fitnessGoal = profile.fitnessGoal

            if let data = profile.profileImageData {
                profileImage = ImageDownsampler.downsample(imageData: data, to: CGSize(width: 120, height: 120))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setProfileImage(from data: Data) {
        // Downsampling avoids keeping large full-resolution camera frames resident in memory.
        profileImage = ImageDownsampler.downsample(imageData: data, to: CGSize(width: 180, height: 180))
        profile?.profileImageData = data
    }

    func save() async {
        guard let repository, let profile else { return }

        isSaving = true
        defer { isSaving = false }

        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.fitnessGoal = fitnessGoal.trimmingCharacters(in: .whitespacesAndNewlines)

        if let weight = Double(bodyWeight) {
            profile.bodyWeight = weight
        }

        do {
            try repository.save(profile: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
