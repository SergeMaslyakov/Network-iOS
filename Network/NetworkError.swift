import Foundation

public enum NetworkError: Error {
    case unexpected
    case invalidParams
    case underlyingError(Error)

    case invalidResponse
    case invalidData

    case httpError(HTTPStatusCode)
    case httpErrorWithData(HTTPStatusCode, Any)

    case invalidQuery(String)
    case invalidEndpointURL(String)

    case encodingError(Error)
    case decodingError(Error)

    case unauthorizedState(String)

    public var statusCode: HTTPStatusCode {
        switch self {
        case .httpError(let status): return status
        case .httpErrorWithData(let status, _): return status
        default: return .badResponse
        }
    }
}
