import Foundation

struct ExerciseItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let categoryID: Int
    let description: String
}

struct ExerciseCategoryItem: Identifiable, Hashable {
    let id: Int
    let name: String
}

private struct ExercisePageResponse: Decodable {
    struct Item: Decodable {
        let id: Int
        let name: String?
        let category: Int?
        let description: String?
    }

    let count: Int
    let next: String?
    let previous: String?
    let results: [Item]
}

private struct ExerciseCategoryResponse: Decodable {
    struct Item: Decodable {
        let id: Int
        let name: String
    }

    let results: [Item]
}

private struct ExerciseEndpoint: Endpoint {
    let page: Int
    let pageSize: Int

    var path: String { "api/v2/exercise/" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: "2"),
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "offset", value: String(page * pageSize))
        ]
    }
}

private struct ExerciseCategoryEndpoint: Endpoint {
    var path: String { "api/v2/exercisecategory/" }
}

final class ExerciseAPIService {
    private let client: APIClient

    init(client: APIClient = APIClient(baseURL: ExerciseAPIService.defaultBaseURL)) {
        self.client = client
    }

    private static let defaultBaseURL = URL(string: "https://wger.de") ?? URL(fileURLWithPath: "/")

    func fetchExercises(page: Int, pageSize: Int = 30) async throws -> (items: [ExerciseItem], hasMore: Bool) {
        let response = try await client.request(ExerciseEndpoint(page: page, pageSize: pageSize), as: ExercisePageResponse.self)

        let items = response.results.compactMap { item -> ExerciseItem? in
            guard let name = item.name,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let category = item.category else {
                return nil
            }

            return ExerciseItem(
                id: item.id,
                name: name,
                categoryID: category,
                description: item.description ?? ""
            )
        }

        let hasMore = response.next != nil || (page + 1) * pageSize < response.count
        return (items, hasMore)
    }

    func fetchCategories() async throws -> [ExerciseCategoryItem] {
        let response = try await client.request(ExerciseCategoryEndpoint(), as: ExerciseCategoryResponse.self)
        return response.results.map { ExerciseCategoryItem(id: $0.id, name: $0.name) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
