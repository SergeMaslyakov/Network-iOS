import XCTest
@testable import Core

class RefreshJobWorkerTests: XCTestCase {

    private var worker: RefreshJobWorker!
    private var promise: XCTestExpectation!

    override func setUp() {
        super.setUp()

        worker = RefreshJobWorker()
        promise = XCTestExpectation(description: "RefreshJobWorker")
    }

    override func tearDown() {
        promise = nil
        worker = nil

        super.tearDown()
    }

    func testSingleRefreshInterval() {
        worker.start(refreshInterval: 0.2, shouldRepeat: false) { [weak self] in
            self?.promise.fulfill()
        }

        wait(for: [promise], timeout: 0.3)
    }

    func testRepeatingRefreshInterval() {
        var count = 2

        worker.start(refreshInterval: 0.2) { [weak self] in
            count -= 1

            if count == 0 {
                self?.promise.fulfill()
            }

        }

        wait(for: [promise], timeout: 0.5)
    }
}
