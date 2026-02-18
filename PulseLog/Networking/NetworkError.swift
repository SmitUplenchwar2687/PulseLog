import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, Data)
    case decodingFailed(Error)
    case simulatedFailure

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse:
            return "Received an invalid server response."
        case .httpStatus(let code, _):
            return "Server returned HTTP status \(code)."
        case .decodingFailed:
            return "Could not decode server response."
        case .simulatedFailure:
            return "Simulated network failure."
        }
    }
}
