import Foundation

///
/// Acknowledgements:
/// - Alamofire - https://github.com/Alamofire
/// - Max Sokolov - https://github.com/maxsokolov/Leeloo/
///

public enum NetworkLayer {

    // MARK: - Supporting data

    // swiftlint:disable weak_delegate
    public struct Configuration {

        public init(timeout: TimeInterval,
                    baseURL: URL,
                    sessionDelegate: URLSessionDelegate,
                    authProvider: AuthorizationProvider,
                    responseDecoder: NetworkResponseDecoding,
                    requestEncoder: NetworkRequestEncoding,
                    defaultBehaviors: [NetworkRequestBehavior]) {

            self.timeout = timeout
            self.baseURL = baseURL
            self.sessionDelegate = sessionDelegate
            self.authProvider = authProvider
            self.responseDecoder = responseDecoder
            self.requestEncoder = requestEncoder
            self.defaultBehaviors = defaultBehaviors
        }

        let timeout: TimeInterval
        let baseURL: URL
        let sessionDelegate: URLSessionDelegate
        let authProvider: AuthorizationProvider
        let responseDecoder: NetworkResponseDecoding
        let requestEncoder: NetworkRequestEncoding
        let defaultBehaviors: [NetworkRequestBehavior]
    }
    // swiftlint:enable weak_delegate
}

public protocol NetworkClient {

    var sendImmediately: Bool { get set }
    var urlSession: URLSession { get }

    func sendRequest<T: Decodable>(endpoint: EndpointDescriptor,
                                   completion: @escaping (Result<T, NetworkError>) -> Void) throws -> URLSessionDataTask

    func sendRequest(endpoint: EndpointDescriptor, sendImmediately: Bool,
                     completion: @escaping (Result<Data?, NetworkError>) -> Void) throws -> URLSessionDataTask
}

// swiftlint:disable function_parameter_count
extension NetworkClient {

    // MARK: - URL request assembler

    func assembleURLRequest(for endpoint: EndpointDescriptor,
                            with baseURL: URL,
                            _ encoder: NetworkRequestEncoding,
                            _ authProvider: AuthorizationProvider,
                            _ behaviours: [NetworkRequestBehavior],
                            _ timeout: TimeInterval) throws -> URLRequest {
        var urlRequest: URLRequest

        let finalBaseURL = endpoint.overriddenBaseURL ?? baseURL
        let url = finalBaseURL.appendingPathComponent(endpoint.path)

        /// URL queries
        let urlComponents = URLComponents(string: url.absoluteString)
        let components = addURLComponents(from: endpoint, behaviours, existingComponents: urlComponents)

        urlRequest = URLRequest(url: components?.url ?? url, timeoutInterval: timeout)
        urlRequest.httpMethod = endpoint.method.rawValue

        /// Headers
        let headers = behaviours.map { $0.additionalHeaders }.reduce([], +) + endpoint.headers
        headers.forEach { data in
            urlRequest.setValue(data.value, forHTTPHeaderField: data.key)
        }
        urlRequest.setValue("0", forHTTPHeaderField: "Content-Length")

        /// Body
        if let params = endpoint.params {
            do {
                let body = try encoder.encode(params: params)
                urlRequest.httpBody = body
                urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        /// Authorization
        if endpoint.authRequired {
            try authProvider.sign(request: &urlRequest)
        }

        return urlRequest
    }

    // MARK: - URL queries

    func addURLComponents(from endpoint: EndpointDescriptor,
                          _ behaviours: [NetworkRequestBehavior],
                          existingComponents: URLComponents?) -> URLComponents? {

        let queries = behaviours.map { $0.additionalQueries }.reduce([], +) + endpoint.queries

        if !queries.isEmpty {
            var components = existingComponents ?? URLComponents()
            components.queryItems = queries.map { URLQueryItem(name: $0, value: $1) }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")

            return components
        }

        return existingComponents
    }

    // MARK: - Error handling

    func processTaskError<T>(error: Error?, completion: @escaping ((Result<T, NetworkError>) -> Void)) {
        let responseError: NetworkError
        if let error = error {
            responseError = .underlyingError(error)
        } else {
            responseError = .invalidResponse
        }
        completion(.failure(responseError))
    }

    // MARK: - Validation

    func validate(request: URLRequest,
                  response: HTTPURLResponse,
                  data: Data?,
                  _ completion: @escaping (Result<Data?, NetworkError>) -> Void) {

        let statusCode = HTTPStatusCode(rawValue: response.statusCode) ?? .badResponse

        if !statusCode.isSuccess {
            if let jsonData = data, response.containsJSONContent {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                    completion(.failure(.httpErrorWithData(statusCode, json)))
                } catch {
                    completion(.failure(.httpError(statusCode)))
                }
            } else if let textData = data, response.containsTextContent {
                let text = String(data: textData, encoding: .utf8) ?? ""
                completion(.failure(.httpErrorWithData(statusCode, text)))
            } else {
                completion(.failure(.httpError(statusCode)))
            }
        } else {
            completion(.success(data))
        }
    }

    // MARK: - Parsing

    func parse<T: Decodable>(data: Data, decoder: NetworkResponseDecoding,
                             _ keyPath: String?,
                             _ completion: @escaping (Result<T, NetworkError>) -> Void) {
        do {
            let result: T = try decoder.decode(data: data, keyPath: keyPath)
            completion(.success(result))
        } catch {
            completion(.failure(.decodingError(error)))
        }
    }

}
// swiftlint:enable function_parameter_count
