import Foundation

public final class DebugBehavior: NetworkRequestBehavior {

    private let logger: NetworkLogger

    public init(logger: NetworkLogger) {
        self.logger = logger
    }

    public func willSend(request: URLRequest, session: URLSession) {
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

        let date = Date()
        let fract = date.timeIntervalSince1970 - TimeInterval(Int(date.timeIntervalSince1970))
        let log = """
        \n******** BEGIN REQUEST LOG ********
          TS:       \(date) + \(fract)
          URL:      \(request.url?.absoluteString ?? "null")
          Method:   \(request.httpMethod ?? "null")
          Headers:  \(allHeaders)
          Body:     \(bodyStr.trimmingCharacters(in: .whitespacesAndNewlines))
        ******** END REQUEST LOG **********

        """

        logger.verbose(log)
    }

    public func didReceive(response: HTTPURLResponse, data: Data?, request: URLRequest) {
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

        let date = Date()
        let fract = date.timeIntervalSince1970 - TimeInterval(Int(date.timeIntervalSince1970))
        let log = """
        \n******** BEGIN RESPONSE LOG ********
          TS:       \(date) + \(fract)
          URL:      \(response.url?.absoluteString ?? "null")
          Code:     \(statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: statusCode)))
          Headers:  \(headers)
          Body:     \(bodyStr.trimmingCharacters(in: .whitespacesAndNewlines))
        ******** END RESPONSE LOG **********

        """

        logger.verbose(log)
    }
}
