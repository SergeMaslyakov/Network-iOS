import Foundation

public final class DefaultAuthorizationProvider: AuthorizationProvider {
    public init() { }

    public func sign(request: inout URLRequest) throws {
        // Do nothing - without authorization
    }

    public func refreshAuthToken() throws {
        // Do nothing - without authorization
    }
}
