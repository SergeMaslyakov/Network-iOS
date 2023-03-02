import Foundation

public class NetworkClientImpl: NetworkClient {
    private let timeout: TimeInterval
    private let baseURL: URL
    private let apiVers: String?
    private let defaultBehaviors: [NetworkRequestBehavior]

    private let responseDecoder: NetworkResponseDecoding
    private let requestEncoder: NetworkRequestEncoding
    private let authProvider: AuthorizationProvider

    public let urlSession: URLSession
    public let isBackgroundSession: Bool
    public var sendImmediately: Bool = true

    public init(configuration: NetworkLayer.Configuration, sessionConfiguration: URLSessionConfiguration) {
        timeout = configuration.timeout
        baseURL = configuration.baseURL
        apiVers = configuration.apiVers
        authProvider = configuration.authProvider
        requestEncoder = configuration.requestEncoder
        responseDecoder = configuration.responseDecoder
        defaultBehaviors = configuration.defaultBehaviors
        isBackgroundSession = configuration.isBackgroundSession

        urlSession = URLSession(configuration: sessionConfiguration, delegate: configuration.sessionDelegate, delegateQueue: .main)
    }
}

// MARK: - NetworkClientProtocol

public extension NetworkClientImpl {
    func sendRequest<T: Decodable>(endpoint: EndpointDescriptor,
                                   completion: @escaping (Result<T, NetworkError>) -> Void) throws -> NetworkLayer.SessionTaskData {
        let taskData = try sendRequest(endpoint: endpoint, sendImmediately: false) { [weak self] result in
            guard let self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(data):
                if let data {
                    do {
                        let model: T = try self.parse(data: data, decoder: self.responseDecoder, endpoint.keyPath)
                        completion(.success(model))
                    } catch {
                        completion(.failure(error as? NetworkError ?? .unexpected))
                    }
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

    func sendRequest(endpoint: EndpointDescriptor,
                     sendImmediately: Bool,
                     completion: @escaping (Result<Data?, NetworkError>) -> Void) throws -> NetworkLayer.SessionTaskData {
        let dataRequest = try makeRequest(endpoint: endpoint, completion: completion)
        let task: URLSessionDataTask

        defer {
            if sendImmediately {
                task.resume()
            }
        }

        if isBackgroundSession {
            // session delegate is responsible for all completion handlers
            task = urlSession.dataTask(with: dataRequest.request)
            return NetworkLayer.SessionTaskData(task: task, completionHandler: dataRequest.completion)
        } else {
            task = urlSession.dataTask(with: dataRequest.request, completionHandler: dataRequest.completion)
            return NetworkLayer.SessionTaskData(task: task)
        }
    }

    func downloadTask(endpoint: EndpointDescriptor,
                      sendImmediately: Bool,
                      completion: @escaping (Result<URL, NetworkError>) -> Void) throws -> NetworkLayer.SessionDownloadTaskData {
        let dataRequest = try makeDownloadRequest(endpoint: endpoint, completion: completion)
        let task: URLSessionDownloadTask

        defer {
            if sendImmediately {
                task.resume()
            }
        }

        if isBackgroundSession {
            // session delegate is responsible for all completion handlers
            task = urlSession.downloadTask(with: dataRequest.request)
            return NetworkLayer.SessionDownloadTaskData(task: task, completionHandler: dataRequest.completion)
        } else {
            task = urlSession.downloadTask(with: dataRequest.request, completionHandler: dataRequest.completion)
            return NetworkLayer.SessionDownloadTaskData(task: task)
        }
    }
}

// MARK: - NetworkClientAsync

public extension NetworkClientImpl {
    func sendRequest<T: Decodable>(
        endpoint: EndpointDescriptor
    ) async throws -> T {
        let dataRequest = try makeRequest(endpoint: endpoint) { _ in }

        let task = Task {
            let data = try await self.urlSession.data(for: dataRequest.request)
            try Task.checkCancellation()

            return try self.responseDecoder.decode(data: data.0, keyPath: endpoint.keyPath) as T
        }

        return try await task.value
    }

    func sendRequest(
        endpoint: EndpointDescriptor
    ) async throws -> Data {
        let dataRequest = try makeRequest(endpoint: endpoint) { _ in }

        let task = Task {
            let data = try await self.urlSession.data(for: dataRequest.request)
            try Task.checkCancellation()

            return data.0
        }

        return try await task.value
    }

    @available(iOS 15.0, *)
    func sendDownloadRequest(
        endpoint: EndpointDescriptor
    ) async throws -> URL {
        let dataRequest = try makeDownloadRequest(endpoint: endpoint) { _ in }

        let task = Task {
            let data = try await self.urlSession.download(for: dataRequest.request)
            try Task.checkCancellation()

            guard let httpResponse = data.1 as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(endpoint.fileName)

            // to delete a file with the same name if needed
            try? FileManager.default.removeItem(at: destinationURL)

            // move file to document directory
            try FileManager.default.copyItem(at: data.0, to: destinationURL)

            // Did receive hook
            self.defaultBehaviors.forEach {
                $0.didReceive(response: httpResponse, data: nil, request: dataRequest.request)
            }

            return try self.validate(request: dataRequest.request,
                                     response: httpResponse,
                                     fileURL: destinationURL)
        }

        return try await task.value
    }
}

// MARK: - Helpers

private extension NetworkClientImpl {
    typealias DataURLRequest = (request: URLRequest, completion: (URL?, URLResponse?, Error?) -> Void)
    typealias DataRequest = (request: URLRequest, completion: (Data?, URLResponse?, Error?) -> Void)

    func makeDownloadRequest(endpoint: EndpointDescriptor,
                             completion: ((Result<URL, NetworkError>) -> Void)?) throws -> DataURLRequest {
        let encoder = endpoint.customEncoder ?? requestEncoder
        let apiVers = endpoint.apiVers ?? self.apiVers
        let request = try assembleURLRequest(for: endpoint,
                                             with: baseURL,
                                             apiVers,
                                             encoder,
                                             authProvider,
                                             defaultBehaviors,
                                             timeout)

        /// Before send hook
        defaultBehaviors.forEach {
            $0.willSend(request: request, session: urlSession)
        }

        let completionHandler: ((URL?, URLResponse?, Error?) -> Void) = { [weak self] url, response, error in
            guard let self else { return }

            guard error == nil, let response = response as? HTTPURLResponse, let url else {
                completion?(.failure(.makeResponseError(from: error)))
                return
            }

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(endpoint.fileName)

            // to delete a file with the same name if needed
            try? FileManager.default.removeItem(at: destinationURL)

            do {
                // move file to document directory
                try FileManager.default.copyItem(at: url, to: destinationURL)
            } catch {
                completion?(.failure(.makeResponseError(from: error)))
                return
            }

            // Did receive hook
            self.defaultBehaviors.forEach {
                $0.didReceive(response: response, data: nil, request: request)
            }

            do {
                let validatedURL = try self.validate(request: request, response: response, fileURL: destinationURL)
                completion?(.success(validatedURL))
            } catch {
                completion?(.failure(error as? NetworkError ?? .unexpected))
            }
        }

        return DataURLRequest(request: request, completion: completionHandler)
    }

    func makeRequest(endpoint: EndpointDescriptor,
                     completion: ((Result<Data?, NetworkError>) -> Void)?) throws -> DataRequest {
        let encoder = endpoint.customEncoder ?? requestEncoder
        let apiVers = endpoint.apiVers ?? self.apiVers
        let request = try assembleURLRequest(for: endpoint,
                                             with: baseURL,
                                             apiVers,
                                             encoder,
                                             authProvider,
                                             defaultBehaviors,
                                             timeout)

        /// Before send hook
        defaultBehaviors.forEach {
            $0.willSend(request: request, session: urlSession)
        }

        let completionHandler: ((Data?, URLResponse?, Error?) -> Void) = { [weak self] data, response, error in
            guard let self else { return }

            guard error == nil, let response = response as? HTTPURLResponse else {
                completion?(.failure(.makeResponseError(from: error)))
                return
            }

            /// Did receive hook
            self.defaultBehaviors.forEach {
                $0.didReceive(response: response, data: data, request: request)
            }

            do {
                let validatedData = try self.validate(request: request, response: response, data: data)
                completion?(.success(validatedData))
            } catch {
                completion?(.failure(error as? NetworkError ?? .unexpected))
            }
        }

        return DataRequest(request: request, completion: completionHandler)
    }
}
