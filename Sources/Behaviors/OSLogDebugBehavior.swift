import Foundation
import os

open class OSLogDebugBehavior: NetworkRequestBehavior {
    public struct DebugData {
        let url: String
        let code: String
        let method: String
        let headers: String
        let body: String
    }

    private let log: OSLog

    public init(subsystem: String) {
        log = OSLog(subsystem: subsystem, category: "Network")
    }

    public func willSend(request: URLRequest, session: URLSession) {
        guard shouldLogRequest(request) else { return }

        let data = extractSentData(request: request, session: session)

        let str = """
        *** REQUEST
          URL:      \(data.url)
          Method:   \(data.method)
          Headers:  \(data.headers)
          Body:     \(data.body)

        """

        os_log("%{public}s", log: log, type: .debug, str)
    }

    public func didReceive(response: HTTPURLResponse, data: Data?, request: URLRequest) {
        guard shouldLogResponse(response) else { return }

        let data = extractReceivedData(response: response, data: data, request: request)

        let str = """
        *** RESPONSE
          URL:      \(data.url)
          Code:     \(data.code)
          Headers:  \(data.headers)
          Body:     \(data.body)

        """

        os_log("%{public}s", log: log, type: .debug, str)
    }

    // MARK: - Helpers

    open func shouldLogRequest(_ request: URLRequest) -> Bool {
        // override point for filtering requests
        true
    }

    open func shouldLogResponse(_ response: HTTPURLResponse) -> Bool {
        // override point for filtering responses
        true
    }

    func extractSentData(request: URLRequest, session: URLSession) -> DebugData {
        let defaultHeaders = (session.configuration.httpAdditionalHeaders as? [String: String]) ?? [:]
        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        let allHeaders = requestHeaders.merging(defaultHeaders, uniquingKeysWith: { f, _ in f })
        let bodyStr: String

        if let bodyData = request.httpBody {
            if request.containsXWWWFormContent || request.containsJSONContent || request.containsTextContent {
                bodyStr = String(data: bodyData, encoding: .utf8) ?? "<invalid body data>"
            } else {
                bodyStr = "<binary data>"
            }
        } else {
            bodyStr = "null"
        }

        return DebugData(url: "\(request.url?.absoluteString ?? "null")",
                         code: "",
                         method: "\(request.httpMethod ?? "null")",
                         headers: "\(allHeaders)",
                         body: "\(bodyStr.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    func extractReceivedData(response: HTTPURLResponse, data: Data?, request: URLRequest) -> DebugData {
        let headers: [String: String] = (response.allHeaderFields as? [String: String]) ?? [:]
        let statusCode = response.statusCode
        let bodyStr: String

        if let data {
            if response.containsJSONContent || response.containsXWWWFormContent || response.containsTextContent {
                bodyStr = String(data: data, encoding: .utf8) ?? "<invalid body data>"
            } else {
                bodyStr = "<binary data>"
            }
        } else {
            bodyStr = "null"
        }

        return DebugData(url: "\(response.url?.absoluteString ?? "null")",
                         code: "\(statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: statusCode)))",
                         method: "",
                         headers: "\(headers)",
                         body: "\(bodyStr.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
}
