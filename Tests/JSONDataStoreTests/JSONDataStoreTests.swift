import Testing
import Foundation
import SwiftData
@testable import JSONDataStore

@Suite("JSONDataStore")
struct JSONDataStoreTests {
    @Test("Placeholder - JSONStore can be constructed")
    func testStoreInitialization() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test-db.json")
        let schema = Schema([])
        let config = JSONStoreConfiguration(name: "test", schema: schema, fileURL: fileURL)
        let store = try JSONStore(config)
        #expect(store.configuration.fileURL == fileURL)
    }
}
