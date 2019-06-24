import Foundation

///
/// Simple multipart encoder (it doesn't suit for big images and videos)
///
/// Acknowledgements:
/// - Alamofire - https://github.com/Alamofire
///
public final class MultipartFormEncoder: NetworkRequestEncoding {

    private let dataKey: String
    private let boundaryToken: String

    public init(boundaryToken: String, dataKey: String) {
        self.boundaryToken = boundaryToken
        self.dataKey = dataKey
    }

    // MARK: - NetworkRequestEncoding

    public func encode(params: [String: Any]) throws -> Data {
        guard let data = params[dataKey] as? MultipartData else { throw CodingError.missingData }

        var mutableParams = params
        mutableParams.removeValue(forKey: dataKey)

        return createMultipartBody(fromMultipartData: data, params: mutableParams)
    }

    // MARK: - Implementation

    private enum BoundaryType {
        case initial(String)
        case final(String)

        static let crlf = "\r\n"
        static let crlfCrlf = "\r\n\r\n"

        var boundary: Data {
            let boundaryText: String

            switch self {
            case .initial(let token):
                boundaryText = "--\(token)\r\n"
            case .final(let token):
                boundaryText = "--\(token)--\r\n"
            }

            return boundaryText.data(using: .utf8, allowLossyConversion: false) ?? Data()
        }
    }

    private func createMultipartBody(fromMultipartData data: MultipartData, params: [String: Any]) -> Data {
        var multipartData = Data()

        /// params
        params.forEach { (key: String, value: Any) in

            let data = "\(value)".data(using: .utf8) ?? Data()

            multipartData.append(BoundaryType.initial(boundaryToken).boundary)

            multipartData.append("Content-Disposition: form-data; name=\"\(key)\"\(BoundaryType.crlf)".data(using: .utf8) ?? Data())
            multipartData.append("Content-Length: \(data.count)\(BoundaryType.crlfCrlf)".data(using: .utf8) ?? Data())
            multipartData.append(data)
            multipartData.append("\(BoundaryType.crlf)".data(using: .utf8) ?? Data())
        }

        /// binary data
        multipartData.append(BoundaryType.initial(boundaryToken).boundary)
        let contentDisposition = "Content-Disposition: form-data; name=\"file\"; filename=\"\(data.filename)\"\(BoundaryType.crlf)"

        multipartData.append(contentDisposition.data(using: .utf8) ?? Data())
        multipartData.append("Content-Length: \(data.data.count)\(BoundaryType.crlf)".data(using: .utf8) ?? Data())
        multipartData.append("Content-Type: \(data.mimeType)\(BoundaryType.crlfCrlf)".data(using: .utf8) ?? Data())
        multipartData.append(data.data)
        multipartData.append("\(BoundaryType.crlf)".data(using: .utf8) ?? Data())

        /// final
        multipartData.append(BoundaryType.final(boundaryToken).boundary)

        return multipartData
    }

}
