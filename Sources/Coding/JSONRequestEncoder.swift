import Foundation

public final class JSONRequestEncoder: NetworkRequestEncoding {
    public init() { }

    public func encode(params: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: params, options: [])
    }
}
