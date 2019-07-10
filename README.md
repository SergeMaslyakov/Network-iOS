### Network-iOS framework

`No dendencies, just a plain URLSession`

`Swift 5+`

How to:

#### 1 - Create an instance of NetworkClient, smth like that

```

let configuration = NetworkLayer.Configuration(timeout: 10,
                                               baseURL: "https://github.com",
                                               sessionDelegate: sessionDelegateProvider,
                                               authProvider: DefaultAuthorizationProvider(),
                                               responseDecoder: JSONResponseDecoder(),
                                               requestEncoder: JSONResponseEncoder(),
                                               defaultBehaviors: [DebugBehavior(logger: logger)])

let networkClient = NetworkClientImpl(configuration: configuration, 
                                      sessionConfiguration: config.sessionConfiguration)
``` 

#### 2 - API Endpoint descriptors, e.g.

```
struct SignUpEndpoint: EndpointDescriptor {

    private let data: SignUpDataModel
    private let encoder = WWWFormRequestEncoder()

    init(data: SignUpDataModel) {
        self.data = data
    }

    // MARK: - EndpointDescriptor

    let path: String = "auth/sign_up"
    let method: HTTPMethod = .post

    var headers: HTTPHeaders {
        return ["Content-Type": "application/x-www-form-urlencoded"]
    }

    var customEncoder: NetworkRequestEncoding? {
        return encoder
    }

    var params: [String: Any]? {
        return data.toJSON()
    }

    var authRequired: Bool {
        return false
    }

}

```

#### 3 - Send request (generic or plain request)

```
let endpoint = SignUpEndpoint(data: data)
var task: URLSessionDataTask?

let completion: ((Result<T, NetworkError>) -> Void) = { result in
    switch result {
    case .success(let model):
        // do smth with model
        print(model)
    case .failure(let error):
        // do smth with error
        print(error)
    }
}

do {
    task = try networkClient.sendRequest(endpoint: endpoint, completion: completion)
} catch {
    // catch validation, coding errors
    print(error)
}
```
