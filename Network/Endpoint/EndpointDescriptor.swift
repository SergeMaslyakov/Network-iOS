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

    var overriddenBaseURL: URL? { get }
    var customEncoder: NetworkRequestEncoding? { get }

    var params: [String: Any]? { get }

    var queries: URLQueries { get }
    var headers: HTTPHeaders { get }

    var authRequired: Bool { get }

    var keyPath: String? { get }

}

public extension EndpointDescriptor {

    var overriddenBaseURL: URL? {
        return nil
    }

    var customEncoder: NetworkRequestEncoding? {
        return nil
    }

    var queries: URLQueries {
        return [:]
    }

    var params: [String: Any]? {
        return nil
    }

    var headers: HTTPHeaders {
        return [:]
    }

    var keyPath: String? {
        return nil
    }

    var authRequired: Bool {
        return true
    }
}
