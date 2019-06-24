import Foundation

public protocol NetworkResponseDecoding {
    func decode<T: Decodable>(data: Data, keyPath: String?) throws -> T
    func decode<T: Decodable>(jsonObject: Any, keyPath: String?) throws -> T
}
