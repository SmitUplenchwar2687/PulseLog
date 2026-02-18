import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack(spacing: 16) {
                        profileImageView

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }

                    TextField("Name", text: $viewModel.name)
                    TextField("Weight (kg)", text: $viewModel.bodyWeight)
                        .keyboardType(.decimalPad)
                    TextField("Fitness Goal", text: $viewModel.fitnessGoal, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button {
                        Task {
                            await viewModel.save()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Profile")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                viewModel.configure(context: modelContext)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        viewModel.setProfileImage(from: data)
                    }
                }
            }
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private var profileImageView: some View {
        Group {
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(Circle())
        .background(Circle().fill(Color.secondary.opacity(0.1)))
    }
}
