import SwiftUI
import SwiftData

struct WorkoutTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = WorkoutTrackerViewModel()
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                filterSection

                if viewModel.workouts.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "No Workouts Yet",
                        message: "Log your first workout to build trend data.",
                        systemImage: "figure.strengthtraining.functional"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        // LazyVStack avoids creating off-screen rows and keeps memory flat with long workout histories.
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.workouts) { workout in
                                WorkoutRowView(workout: workout)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task {
                                                await viewModel.deleteWorkout(workout)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .onAppear {
                                        if workout.id == viewModel.workouts.last?.id {
                                            Task {
                                                await viewModel.loadNextPage()
                                            }
                                        }
                                    }
                            }

                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.vertical)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Workout Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .task {
                viewModel.configure(context: modelContext)
            }
            .sheet(isPresented: $showCreateSheet) {
                WorkoutEditorView { input in
                    Task {
                        await viewModel.createWorkout(from: input)
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

    private var filterSection: some View {
        VStack(spacing: 10) {
            Picker("Type", selection: $viewModel.selectedType) {
                ForEach(viewModel.workoutTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Filter by Date", isOn: $viewModel.useDateFilter)

            if viewModel.useDateFilter {
                DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
            }

            Button("Apply Filters") {
                Task {
                    await viewModel.applyFilter()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
