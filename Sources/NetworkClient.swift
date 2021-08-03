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
                    apiVers: String?,
                    sessionDelegate: URLSessionDelegate,
                    isBackgroundSession: Bool,
                    authProvider: AuthorizationProvider,
                    responseDecoder: NetworkResponseDecoding,
                    requestEncoder: NetworkRequestEncoding,
                    defaultBehaviors: [NetworkRequestBehavior]) {
            self.timeout = timeout
            self.baseURL = baseURL
            self.apiVers = apiVers
            self.sessionDelegate = sessionDelegate
            self.isBackgroundSession = isBackgroundSession
            self.authProvider = authProvider
            self.responseDecoder = responseDecoder
            self.requestEncoder = requestEncoder
            self.defaultBehaviors = defaultBehaviors
        }

        let timeout: TimeInterval
        let baseURL: URL
        let apiVers: String?
        let sessionDelegate: URLSessionDelegate
        let isBackgroundSession: Bool
        let authProvider: AuthorizationProvider
        let responseDecoder: NetworkResponseDecoding
        let requestEncoder: NetworkRequestEncoding
        let defaultBehaviors: [NetworkRequestBehavior]
    }

    // swiftlint:enable weak_delegate

    public class SessionTaskData {
        public let task: URLSessionDataTask
        public let completionHandler: ((Data?, URLResponse?, Error?) -> Void)?

        public var loadedData: Data?

        public init(task: URLSessionDataTask, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
            self.task = task
            self.completionHandler = completionHandler
        }
    }

    public class SessionDownloadTaskData {
        public let task: URLSessionDownloadTask
        public let completionHandler: ((URL?, URLResponse?, Error?) -> Void)?

        public init(task: URLSessionDownloadTask, completionHandler: ((URL?, URLResponse?, Error?) -> Void)? = nil) {
            self.task = task
            self.completionHandler = completionHandler
        }
    }
}

public protocol NetworkClient {
    var isBackgroundSession: Bool { get }
    var sendImmediately: Bool { get set }
    var urlSession: URLSession { get }

    func sendRequest<T: Decodable>(endpoint: EndpointDescriptor,
                                   completion: @escaping (Result<T, NetworkError>) -> Void) throws -> NetworkLayer.SessionTaskData

    func sendRequest(endpoint: EndpointDescriptor, sendImmediately: Bool,
                     completion: @escaping (Result<Data?, NetworkError>) -> Void) throws -> NetworkLayer.SessionTaskData

    func downloadTask(endpoint: EndpointDescriptor, sendImmediately: Bool,
                      completion: @escaping (Result<URL, NetworkError>) -> Void) throws -> NetworkLayer.SessionDownloadTaskData
}

// swiftlint:disable function_parameter_count
extension NetworkClient {
    // MARK: - URL request assembler

    func assembleURLRequest(for endpoint: EndpointDescriptor,
                            with baseURL: URL,
                            _ apiVers: String?,
                            _ encoder: NetworkRequestEncoding,
                            _ authProvider: AuthorizationProvider,
                            _ behaviours: [NetworkRequestBehavior],
                            _ timeout: TimeInterval) throws -> URLRequest {
        var urlRequest: URLRequest

        let finalBaseURL = endpoint.overriddenBaseURL ?? baseURL
        let finalApiVers = endpoint.overriddenApiVers ?? apiVers
        let path = (finalApiVers ?? "") + endpoint.path
        let url = finalBaseURL.appendingPathComponent(path)
        let requestTimeout = endpoint.requestTimeout ?? timeout

        // URL queries
        let urlComponents = URLComponents(string: url.absoluteString)
        let components = addURLComponents(from: endpoint, behaviours, existingComponents: urlComponents)

        urlRequest = URLRequest(url: components?.url ?? url, timeoutInterval: requestTimeout)
        urlRequest.httpMethod = endpoint.method.rawValue

        // Headers
        let headers = behaviours.map { $0.additionalHeaders }.reduce([], +) + endpoint.headers
        headers.forEach { data in
            urlRequest.setValue(data.value, forHTTPHeaderField: data.key)
        }
        urlRequest.setValue("0", forHTTPHeaderField: ConstantsKeys.contentLength)

        // Body
        if let params = endpoint.params {
            do {
                let body = try encoder.encode(params: params)
                urlRequest.httpBody = body
                urlRequest.setValue("\(body.count)", forHTTPHeaderField: ConstantsKeys.contentLength)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        // Authorization
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

    func validate(request: URLRequest,
                  response: HTTPURLResponse,
                  fileURL: URL?,
                  _ completion: @escaping (Result<URL, NetworkError>) -> Void) {
        let statusCode = HTTPStatusCode(rawValue: response.statusCode) ?? .badResponse

        if statusCode.isSuccess {
            if let url = fileURL {
                completion(.success(url))
            } else {
                completion(.failure(.invalidData))
            }
        } else {
            completion(.failure(.httpError(statusCode)))
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
