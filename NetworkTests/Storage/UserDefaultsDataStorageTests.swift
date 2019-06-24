import XCTest
@testable import Core

class UserDefaultsDataStorageTests: XCTestCase {

    typealias DataSample = (data: Data?, reference: String)

    private var dataStorage: UserDefaultsDataStorage!
    private var suiteName: String!
    private var keyPrefix: String!

    override func setUp() {
        super.setUp()

        suiteName = "UserDefaultsDataStorageTests"
        keyPrefix = "v_"
        dataStorage = UserDefaultsDataStorage(keyPrefix: keyPrefix, suiteName: suiteName)
    }

    override func tearDown() {
        try? dataStorage.removeAll()

        keyPrefix = nil
        suiteName = nil
        dataStorage = nil

        super.tearDown()
    }

    func testAddingToUserDefaultsDataStorage() {

        let inputData = sampleData()
        var outputData: Data!
        XCTAssertNotNil(inputData.data)

        /// set
        try! dataStorage.setData(inputData.data, forKey: inputData.reference)

        /// get
        outputData = try! dataStorage.getData(forKey: inputData.reference) as? Data
        XCTAssertNotNil(outputData)

        /// reverse data
        let reverseData = String(data: outputData, encoding: .utf8)
        XCTAssertEqual(reverseData, inputData.reference)
    }

    func testRemovingFromUserDefaultsDataStorage() {

        let inputData = sampleData()
        var outputData: Data!
        XCTAssertNotNil(inputData.data)

        /// set
        try! dataStorage.setData(inputData.data, forKey: inputData.reference)
        outputData = try! dataStorage.getData(forKey: inputData.reference) as? Data

        XCTAssertNotNil(outputData)

        /// remove
        try! dataStorage.removeData(forKey: inputData.reference)
        outputData = try! dataStorage.getData(forKey: inputData.reference) as? Data

        XCTAssertNil(outputData)
    }
}

// MARK: - Sample data

private extension UserDefaultsDataStorageTests {

    func sampleData() -> DataSample {
        let str = "SampleData+\(Date().timeIntervalSince1970)"
        return DataSample(data: str.data(using: .utf8), reference: str)
    }

}
