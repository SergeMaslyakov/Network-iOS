import XCTest
@testable import Core

import RxSwift

class CountryServiceTests: XCTestCase {

    private var service: CountryServiceImpl!
    private var promise: XCTestExpectation!

    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        service = CountryServiceImpl()
        promise = XCTestExpectation(description: "CountryService")
    }

    override func tearDown() {
        promise = nil
        service = nil
        disposeBag = nil

        super.tearDown()
    }

    func testFetching() {
        service.countries
            .asObservable()
            .subscribe(onNext: {
                XCTAssertFalse($0.isEmpty)
            }, onError: {
                debugPrint($0)
            })
            .disposed(by: disposeBag)

        service.countries
            .asObservable()
            .subscribe(onNext: {
                XCTAssertFalse($0.isEmpty)
            }, onError: {
                debugPrint($0)
            })
            .disposed(by: disposeBag)

        service.countries
            .asObservable()
            .subscribe(onNext: {
                XCTAssertFalse($0.isEmpty)
            }, onError: {
                debugPrint($0)
            })
            .disposed(by: disposeBag)

        service.countries
            .asObservable()
            .subscribe(onNext: { [unowned self] in
                XCTAssertFalse($0.isEmpty)
                self.promise.fulfill()
            }, onError: {
                debugPrint($0)
            })
            .disposed(by: disposeBag)

        wait(for: [promise], timeout: 2)
    }

    func testMainThreadObserving() {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            self.service.countries
                .asObservable()
                .subscribe(onNext: { _ in
                    XCTAssertTrue(Thread.isMainThread)
                    self.promise.fulfill()
                }, onError: {
                    debugPrint($0)
                })
                .disposed(by: self.disposeBag)
        }

        wait(for: [promise], timeout: 0.5)
    }
}
