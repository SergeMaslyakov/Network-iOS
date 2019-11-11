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
    public let isBackgroundSession: Bool
    public var sendImmediately: Bool = true

    public init(configuration: NetworkLayer.Configuration, sessionConfiguration: URLSessionConfiguration) {
        self.timeout = configuration.timeout
        self.baseURL = configuration.baseURL
        self.authProvider = configuration.authProvider
        self.requestEncoder = configuration.requestEncoder
        self.responseDecoder = configuration.responseDecoder
        self.defaultBehaviors = configuration.defaultBehaviors
        self.isBackgroundSession = configuration.isBackgroundSession

        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: configuration.sessionDelegate, delegateQueue: .main)
    }

    // MARK: - NetworkClientProtocol

    public func sendRequest<T: Decodable>(endpoint: EndpointDescriptor,
                                          completion: @escaping (Result<T, NetworkError>) -> Void) throws -> NetworkLayer.SessionTaskData {

        let taskData = try sendRequest(endpoint: endpoint, sendImmediately: false) { [weak self] result in
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

        defer {
            if sendImmediately {
                taskData.task.resume()
            }
        }

        return taskData
    }

    public func sendRequest(endpoint: EndpointDescriptor, sendImmediately: Bool,
                            completion: @escaping (Result<Data?, NetworkError>) -> Void) throws -> NetworkLayer.SessionTaskData {
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

        let completionHandler: ((Data?, URLResponse?, Error?) -> Void) = { [weak self] (data, response, error) in
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

        let task: URLSessionDataTask

        defer {
            if sendImmediately {
                task.resume()
            }
        }

        if isBackgroundSession {
            // session delegate is responsible for all completion handlers
            task = urlSession.dataTask(with: request)
            return NetworkLayer.SessionTaskData(task: task, completionHandler: completionHandler)
        } else {
            task = urlSession.dataTask(with: request, completionHandler: completionHandler)
            return NetworkLayer.SessionTaskData(task: task)
        }
    }

    public func downloadTask(endpoint: EndpointDescriptor, sendImmediately: Bool,
                             completion: @escaping (Result<URL, NetworkError>) -> Void) throws -> NetworkLayer.SessionDownloadTaskData {
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

        let completionHandler: ((URL?, URLResponse?, Error?) -> Void) = { [weak self] (url, response, error) in
            guard let self = self else { return }

            guard error == nil, let response = response as? HTTPURLResponse, let url = url else {
                self.processTaskError(error: error, completion: completion)
                return
            }

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(endpoint.fileName)

            /// to delete a file with the same name if needed
            try? FileManager.default.removeItem(at: destinationURL)

            var localURL: URL?

            do {
                /// move file to document directory
                try FileManager.default.copyItem(at: url, to: destinationURL)
                localURL = destinationURL
            } catch let error {
                self.processTaskError(error: error, completion: completion)
                return
            }

            /// Did receive hook
            self.defaultBehaviors.forEach {
                $0.didReceive(response: response, data: nil, request: request)
            }

            self.validate(request: request, response: response, fileURL: localURL, completion)

        }

        let task: URLSessionDownloadTask

        defer {
            if sendImmediately {
                task.resume()
            }
        }

        if isBackgroundSession {
            // session delegate is responsible for all completion handlers
            task = urlSession.downloadTask(with: request)
            return NetworkLayer.SessionDownloadTaskData(task: task, completionHandler: completionHandler)
        } else {
            task = urlSession.downloadTask(with: request, completionHandler: completionHandler)
            return NetworkLayer.SessionDownloadTaskData(task: task)
        }

    }
}
