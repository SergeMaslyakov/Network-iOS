import Foundation

public final class JSONRequestEncoder: NetworkRequestEncoding {

    public init() {}

    public func encode(params: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: params, options: [])
    }

}
