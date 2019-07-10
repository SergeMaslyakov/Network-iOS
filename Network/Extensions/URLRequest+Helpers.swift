import Foundation

extension URLRequest {

    var containsJSONContent: Bool {
        if let headers = allHTTPHeaderFields {
            if let value = headers[ConstantsKeys.contentType] {
                return value.contains(ConstantsKeys.applicationJSON)
            }
        }

        return false
    }

    var containsXWWWFormContent: Bool {
        if let headers = allHTTPHeaderFields {
            if let value = headers[ConstantsKeys.contentType] {
                return value.contains(ConstantsKeys.wwwWFormUrlencoded)
            }
        }

        return false
    }

    var containsTextContent: Bool {
        if let headers = allHTTPHeaderFields {
            if let value = headers[ConstantsKeys.contentType] {
                return value.contains("text")
            }
        }

        return false
    }
}
