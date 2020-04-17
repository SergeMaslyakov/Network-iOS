import Foundation

public protocol AuthorizationProvider {

    func sign(request: inout URLRequest) throws

    func refreshAuthToken() throws
}
