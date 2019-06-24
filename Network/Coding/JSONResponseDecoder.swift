import Foundation

public final class JSONResponseDecoder: NetworkResponseDecoding {

    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    public func decode<T: Decodable>(data: Data, keyPath: String? = nil) throws -> T {

        guard let keyPath = keyPath else {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw CodingError.errorWithUnderlying(error)
            }
        }

        if keyPath.isEmpty {
            throw CodingError.emptyKeyPath
        }

        let json: Any

        do {
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            throw CodingError.errorWithUnderlying(error)
        }

        if let dict = json as? [String: Any], let nestedJson = dict[keyPath] {
            let data = try JSONSerialization.data(withJSONObject: nestedJson)
            return try decoder.decode(T.self, from: data)
        } else if let fragment = json as? T {
            return fragment
        }

        throw CodingError.invalidKeyPath
    }

    public func decode<T: Decodable>(jsonObject: Any, keyPath: String? = nil) throws -> T {

        do {
            let data: Data

            if let keyPath = keyPath, let dict = jsonObject as? [String: Any], let nestedJson = dict[keyPath] {
                data = try JSONSerialization.data(withJSONObject: nestedJson)
            } else {
                data = try JSONSerialization.data(withJSONObject: jsonObject)
            }

            return try decoder.decode(T.self, from: data)
        } catch {
            throw CodingError.errorWithUnderlying(error)
        }

    }
}
