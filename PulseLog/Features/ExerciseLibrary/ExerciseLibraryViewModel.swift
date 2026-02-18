import Foundation

@MainActor
final class ExerciseLibraryViewModel: TrackedViewModel {
    @Published private(set) var visibleExercises: [ExerciseItem] = []
    @Published private(set) var categories: [ExerciseCategoryItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published var errorMessage: String?

    @Published var searchText = "" {
        didSet { applyFilters() }
    }

    @Published var selectedCategoryID: Int? {
        didSet { applyFilters() }
    }

    private var allExercises: [ExerciseItem] = []
    private let service: ExerciseAPIService
    private var page = 0
    private var hasMorePages = true

    init(service: ExerciseAPIService = ExerciseAPIService()) {
        self.service = service
        super.init(typeName: String(describing: ExerciseLibraryViewModel.self))
    }

    func loadInitialDataIfNeeded() async {
        guard allExercises.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            enum LibraryLoadResult {
                case categories([ExerciseCategoryItem])
                case firstPage(items: [ExerciseItem], hasMore: Bool)
            }

            let results = try await withThrowingTaskGroup(of: LibraryLoadResult.self) { group in
                group.addTask { [service] in
                    let categories = try await service.fetchCategories()
                    return .categories(categories)
                }

                group.addTask { [service] in
                    let page = try await service.fetchExercises(page: 0)
                    return .firstPage(items: page.items, hasMore: page.hasMore)
                }

                var collected: [LibraryLoadResult] = []
                for try await result in group {
                    collected.append(result)
                }
                return collected
            }

            var fetchedCategories: [ExerciseCategoryItem] = []
            var firstPageItems: [ExerciseItem] = []
            var firstPageHasMore = false

            for result in results {
                switch result {
                case .categories(let categories):
                    fetchedCategories = categories
                case .firstPage(let items, let hasMore):
                    firstPageItems = items
                    firstPageHasMore = hasMore
                }
            }

            categories = fetchedCategories
            allExercises = firstPageItems
            hasMorePages = firstPageHasMore
            page = 1
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadNextPageIfNeeded(currentItem: ExerciseItem) async {
        guard hasMorePages else { return }
        guard !isLoadingMore else { return }
        guard currentItem.id == visibleExercises.last?.id else { return }

        isLoadingMore = true

        do {
            let nextPage = try await service.fetchExercises(page: page)
            allExercises.append(contentsOf: nextPage.items)
            hasMorePages = nextPage.hasMore
            page += 1
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    private func applyFilters() {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        visibleExercises = allExercises.filter { item in
            let categoryMatch = selectedCategoryID == nil || selectedCategoryID == item.categoryID
            let searchMatch = normalizedSearch.isEmpty || item.name.lowercased().contains(normalizedSearch)
            return categoryMatch && searchMatch
        }
    }
}
