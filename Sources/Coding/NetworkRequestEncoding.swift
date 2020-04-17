import Foundation

public protocol NetworkRequestEncoding {
    func encode(params: [String: Any]) throws -> Data
}
