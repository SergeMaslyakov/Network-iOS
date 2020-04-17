import Foundation

extension HTTPURLResponse {

    var containsJSONContent: Bool {
        if let headers = allHeaderFields as? [String: String] {
            if let value = headers[ConstantsKeys.contentType] {
                return value.contains(ConstantsKeys.applicationJSON)
            }
        }

        return false
    }

    var containsXWWWFormContent: Bool {
        if let headers = allHeaderFields as? [String: String] {
            if let value = headers[ConstantsKeys.contentType] {
                return value.contains(ConstantsKeys.wwwFormUrlencoded)
            }
        }

        return false
    }

    var containsTextContent: Bool {
        if let headers = allHeaderFields as? [String: String] {
            if let value = headers[ConstantsKeys.contentType] {
                return value.contains("text")
            }
        }

        return false
    }
}
