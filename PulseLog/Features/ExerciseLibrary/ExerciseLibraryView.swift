import SwiftUI

struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading exercises...")
                } else if viewModel.visibleExercises.isEmpty {
                    EmptyStateView(
                        title: "No Matching Exercises",
                        message: "Try another search keyword or category.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    List(viewModel.visibleExercises) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.headline)
                            Text(categoryName(for: item.categoryID))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .onAppear {
                            Task {
                                await viewModel.loadNextPageIfNeeded(currentItem: item)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Exercise Library")
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Categories") {
                            viewModel.selectedCategoryID = nil
                        }

                        ForEach(viewModel.categories) { category in
                            Button(category.name) {
                                viewModel.selectedCategoryID = category.id
                            }
                        }
                    } label: {
                        Label("Category", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                await viewModel.loadInitialDataIfNeeded()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private func categoryName(for categoryID: Int) -> String {
        viewModel.categories.first(where: { $0.id == categoryID })?.name ?? "Category \(categoryID)"
    }
}
