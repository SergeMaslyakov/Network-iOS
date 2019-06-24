import Foundation

///
/// Acknowledgements:
/// - Alamofire - https://github.com/Alamofire
/// - Max Sokolov - https://github.com/maxsokolov/Leeloo/
///

public class NetworkClientImpl: NetworkClient {

    private let timeout: TimeInterval
    private let baseURL: URL
    private let defaultBehaviors: [NetworkRequestBehavior]

    private let responseDecoder: NetworkResponseDecoding
    private let requestEncoder: NetworkRequestEncoding
    private let authProvider: AuthorizationProvider

    public let urlSession: URLSession
    public var sendImmediately: Bool = true

    public init(configuration: NetworkLayer.Configuration, sessionConfiguration: URLSessionConfiguration) {
        self.timeout = configuration.timeout
        self.baseURL = configuration.baseURL
        self.authProvider = configuration.authProvider
        self.requestEncoder = configuration.requestEncoder
        self.responseDecoder = configuration.responseDecoder
        self.defaultBehaviors = configuration.defaultBehaviors

        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: configuration.sessionDelegate, delegateQueue: .main)
    }

    // MARK: - NetworkClientProtocol

    public func sendRequest<T: Decodable>(endpoint: EndpointDescriptor,
                                          completion: @escaping (Result<T, NetworkError>) -> Void) throws -> URLSessionDataTask {

        let task = try sendRequest(endpoint: endpoint, sendImmediately: false) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                if let data = data {
                    self.parse(data: data, decoder: self.responseDecoder, endpoint.keyPath, completion)
                } else {
                    completion(.failure(.invalidData))
                }

            }
        }

        if sendImmediately {
            task.resume()
        }

        return task
    }

    public func sendRequest(endpoint: EndpointDescriptor, sendImmediately: Bool,
                            completion: @escaping (Result<Data?, NetworkError>) -> Void) throws -> URLSessionDataTask {
        let encoder = endpoint.customEncoder ?? requestEncoder
        let request = try assembleURLRequest(for: endpoint,
                                             with: baseURL,
                                             encoder,
                                             authProvider,
                                             defaultBehaviors,
                                             timeout)

        /// Before send hook
        defaultBehaviors.forEach {
            $0.willSend(request: request, session: urlSession)
        }

        let task = urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }

            guard error == nil, let response = response as? HTTPURLResponse else {
                self.processTaskError(error: error, completion: completion)
                return
            }

            /// Did receive hook
            self.defaultBehaviors.forEach {
                $0.didReceive(response: response, data: data, request: request)
            }

            self.validate(request: request, response: response, data: data, completion)
        }

        if sendImmediately {
            task.resume()
        }

        return task
    }
}
