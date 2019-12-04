import Foundation

open class DebugBehavior: NetworkRequestBehavior {

    public struct DebugData {
        let ts: String
        let url: String
        let code: String
        let method: String
        let headers: String
        let body: String
    }

    private let bodyMaxLength: Int
    private let logger: NetworkLogger

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private var timestamp: String {
        let date = Date()
        let fract = Int((date.timeIntervalSince1970 - TimeInterval(Int(date.timeIntervalSince1970)))*1000)
        return "\(dateFormatter.string(from: date)).\(fract)"
    }

    public init(logger: NetworkLogger, bodyMaxLength: Int = Int.max) {
        self.logger = logger
        self.bodyMaxLength = max(0, bodyMaxLength)
    }

    public func willSend(request: URLRequest, session: URLSession) {
        guard shouldLogRequest(request) else { return }

        let data = extractSentData(request: request, session: session)
        let truncated = data.body.count > bodyMaxLength ? " ...truncated(\(data.body.count) >> \(bodyMaxLength))" : ""

        let log = """
        \n******** BEGIN REQUEST LOG ********
          TS:       \(data.ts)
          URL:      \(data.url)
          Method:   \(data.method)
          Headers:  \(data.headers)
          Body:     \(String(data.body.prefix(bodyMaxLength)) + truncated)
        ******** END REQUEST LOG **********

        """

        logger.verbose(log)
    }

    public func didReceive(response: HTTPURLResponse, data: Data?, request: URLRequest) {
        guard shouldLogResponse(response) else { return }

        let data = extractReceivedData(response: response, data: data, request: request)
        let truncated = data.body.count > bodyMaxLength ? " ...truncated(\(data.body.count) >> \(bodyMaxLength))" : ""

        let log = """
        \n******** BEGIN RESPONSE LOG ********
          TS:       \(data.ts)
          URL:      \(data.url)
          Code:     \(data.code)
          Headers:  \(data.headers)
          Body:     \(String(data.body.prefix(bodyMaxLength)) + truncated)
        ******** END RESPONSE LOG **********

        """

        logger.verbose(log)
    }

    // MARK: - Helpers
    
    open func shouldLogRequest(_ request: URLRequest) -> Bool {
        // override point for filtering requests
        return true
    }

    open func shouldLogResponse(_ response: HTTPURLResponse) -> Bool {
        // override point for filtering responses
        return true
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

        return DebugData(ts: timestamp,
                         url: "\(request.url?.absoluteString ?? "null")",
                         code: "",
                         method: "\(request.httpMethod ?? "null")",
                         headers: "\(allHeaders)",
                         body: "\(bodyStr.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    func extractReceivedData(response: HTTPURLResponse, data: Data?, request: URLRequest) -> DebugData {
        let headers: [String: String] = (response.allHeaderFields as? [String: String]) ?? [:]
        let statusCode = response.statusCode
        let bodyStr: String

        if let data = data {
            if response.containsJSONContent || response.containsXWWWFormContent || response.containsTextContent {
                bodyStr = String(data: data, encoding: .utf8) ?? "<invalid body data>"
            } else {
                bodyStr = "<binary data>"
            }
        } else {
            bodyStr = "null"
        }

        return DebugData(ts: timestamp,
                         url: "\(response.url?.absoluteString ?? "null")",
                         code: "\(statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: statusCode)))",
                         method: "",
                         headers: "\(headers)",
                         body: "\(bodyStr.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
}
