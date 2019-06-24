import Foundation
import RxSwift

public extension NetworkClient {

    func sendRequest(endpoint: EndpointDescriptor) -> Observable<Void> {

        return Observable.create { observer -> Disposable in

            var task: URLSessionDataTask?

            let completion: ((Result<Data?, NetworkError>) -> Void) = { result in
                switch result {
                case .success:
                    observer.onNext(())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }

            do {
                task = try self.sendRequest(endpoint: endpoint, sendImmediately: true, completion: completion)
            } catch {
                if let error = error as? NetworkError {
                    observer.onError(error)
                } else {
                    observer.onError(NetworkError.underlyingError(error))
                }
            }

            return Disposables.create {
                task?.cancel()
            }
        }
    }

    func sendGenericRequest<T: Decodable>(endpoint: EndpointDescriptor) -> Observable<T> {

        return Observable.create { observer -> Disposable in

            var task: URLSessionDataTask?

            let completion: ((Result<T, NetworkError>) -> Void) = { result in
                switch result {
                case .success(let model):
                    observer.onNext(model)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }

            do {
                task = try self.sendRequest(endpoint: endpoint, completion: completion)
            } catch {
                if let error = error as? NetworkError {
                    observer.onError(error)
                } else {
                    observer.onError(NetworkError.underlyingError(error))
                }
            }

            return Disposables.create {
                task?.cancel()
            }
        }

    }
}
