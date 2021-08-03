import Foundation

///
/// Idea: Max Sokolov - https://github.com/maxsokolov/Leeloo/
///

public protocol NetworkRequestBehavior {
    var additionalQueries: URLQueries { get }
    var additionalHeaders: HTTPHeaders { get }

    func willSend(request: URLRequest, session: URLSession)
    func didReceive(response: HTTPURLResponse, data: Data?, request: URLRequest)
}

public extension NetworkRequestBehavior {
    var additionalQueries: URLQueries {
        [:]
    }

    var additionalHeaders: HTTPHeaders {
        [:]
    }

    func willSend(request: URLRequest, session: URLSession) { }

    func didReceive(response: HTTPURLResponse, data: Data?, request: URLRequest) { }
}
