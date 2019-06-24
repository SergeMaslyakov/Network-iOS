import XCTest
@testable import Core

class AppVersionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFactory() {
        XCTAssertNil(AppVersion.makeFromString("3278asdakdkj212j.sa.as,sakasdk"))
        XCTAssertNil(AppVersion.makeFromString("ppp.gggg.ssss"))
        XCTAssertNil(AppVersion.makeFromString("10"))
        XCTAssertNil(AppVersion.makeFromString(""))

        let v0_0 = AppVersion.makeFromString("0.0")!
        XCTAssertNotNil(v0_0)
        XCTAssertTrue(v0_0.major == 0 && v0_0.minor == 0 && v0_0.patch == 0)

        let v0_0_0 = AppVersion.makeFromString("0.0.0")!
        XCTAssertNotNil(v0_0_0)
        XCTAssertTrue(v0_0_0.major == 0 && v0_0_0.minor == 0 && v0_0_0.patch == 0)

        let v3202_37 = AppVersion.makeFromString("3202.37")!
        XCTAssertNotNil(v3202_37)
        XCTAssertTrue(v3202_37.major == 3202 && v3202_37.minor == 37 && v3202_37.patch == 0)

        let v1_3_0 = AppVersion.makeFromString("1.3.0")!
        XCTAssertNotNil(v1_3_0)
        XCTAssertTrue(v1_3_0.major == 1 && v1_3_0.minor == 3 && v1_3_0.patch == 0)

        XCTAssertNotNil(AppVersion.makeZeroVersion())
    }

    func testComparing() {
        let v1_3_0 = AppVersion.makeFromString("1.3.0")!
        let v0_3_1 = AppVersion.makeFromString("0.3.1")!

        XCTAssertFalse(v0_3_1 > v1_3_0)
        XCTAssertFalse(v0_3_1 == v1_3_0)
        XCTAssertTrue(v0_3_1 < v1_3_0)

        let v5_3 = AppVersion.makeFromString("5.3")!
        let v5_3_0 = AppVersion.makeFromString("5.3.0")!

        XCTAssertFalse(v5_3 > v5_3_0)
        XCTAssertTrue(v5_3 == v5_3_0)
        XCTAssertFalse(v5_3 < v5_3_0)

        let v0 = AppVersion.makeZeroVersion()
        let v0_0 = AppVersion.makeFromString("0.0")!

        XCTAssertTrue(v0 == v0_0)
    }

}
