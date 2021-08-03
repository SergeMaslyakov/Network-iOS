import Foundation

public typealias HTTPHeaders = [String: String]
public typealias URLQueries = [String: String]

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol EndpointDescriptor {
    var method: HTTPMethod { get }
    var path: String { get }
    var apiVers: String? { get }

    var overriddenBaseURL: URL? { get }
    var overriddenApiVers: String? { get }
    var customEncoder: NetworkRequestEncoding? { get }

    var requestTimeout: TimeInterval? { get }

    var params: [String: Any]? { get }

    var queries: URLQueries { get }

    var headers: HTTPHeaders { get }

    var authRequired: Bool { get }

    var keyPath: String? { get }

    var fileName: String { get }
}

public extension EndpointDescriptor {
    var apiVers: String? { nil }

    var overriddenBaseURL: URL? { nil }

    var overriddenApiVers: String? { nil }

    var customEncoder: NetworkRequestEncoding? { nil }

    var requestTimeout: TimeInterval? { nil }

    var params: [String: Any]? { nil }

    var queries: URLQueries { [:] }

    var headers: HTTPHeaders { [:] }

    var keyPath: String? { nil }

    var fileName: String { UUID().uuidString }

    var authRequired: Bool { true }
}
