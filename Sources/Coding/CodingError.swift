import Foundation

public enum CodingError: Error {
    case missingData
    case emptyKeyPath
    case invalidKeyPath
    case errorWithUnderlying(Error)
}
