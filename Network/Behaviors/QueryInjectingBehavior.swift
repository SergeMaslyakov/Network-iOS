import Foundation

public final class QueryInjectingBehavior: NetworkRequestBehavior {

    private let query: URLQueries

    public init(query: URLQueries) {
        self.query = query
    }

    public var additionalQueries: URLQueries {
        return query
    }
}
