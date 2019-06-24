import Foundation

public struct MultipartData {

    public init(data: Data, mimeType: String, filename: String) {
        self.data = data
        self.mimeType = mimeType
        self.filename = filename
    }

    let data: Data
    let mimeType: String
    let filename: String
}
