import Foundation

public protocol NetworkLogger: class {

    /// Logs info data
    ///
    /// - Parameter string: The data to be logged as string.
    func info(_ string: String)

    /// Logs info data
    ///
    /// - Parameter string: The data to be logged as string.
    func debug(_ string: String)

    /// Logs warning data
    ///
    /// - Parameter string: The data to be logged as string.
    func warning(_ string: String)

    /// Logs error
    ///
    /// - Parameter string: The data to be logged as string.
    func error(_ string: String)

    /// Logs fatal error
    ///
    /// - Parameter string: The data to be logged as string.
    func fatal(_ string: String)
}
