import Testing
import Foundation
import SwiftData
@testable import JSONDataStore

@Model
class Person {
    var id: Int
    var name: String
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

@Suite("JSONDataStore")
struct JSONDataStoreTests {
    // Helper: create a unique temp file URL
    func tempFileURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent(UUID().uuidString + ".json")
    }

    // Helper: Delete file if it exists
    func deleteFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Save and fetch single model")
    @MainActor
    func testSaveAndFetchSingleModel() async throws {
        let fileURL = tempFileURL()
        defer { deleteFile(fileURL) }
        let config = JSONStoreConfiguration(name: "test", schema: Schema([Person.self]), fileURL: fileURL)
        let container = try ModelContainer(for: Person.self, configurations: config)

        // Save
        let person = Person(id: 1, name: "Alice")
        container.mainContext.insert(person)
        try container.mainContext.save()
        
        // Fetch
        let personFetch = FetchDescriptor<Person>()
        let persons = try container.mainContext.fetch(personFetch)
        
        #expect(persons == [person])
    }

    @Test("Save and fetch multiple models")
    @MainActor
    func testSaveAndFetchMultipleModels() async throws {
        let fileURL = tempFileURL()
        defer { deleteFile(fileURL) }
        let config = JSONStoreConfiguration(name: "test", schema: Schema([Person.self]), fileURL: fileURL)
        let container = try ModelContainer(for: Person.self, configurations: config)
        let people = [
            Person(id: 1, name: "Alice"),
            Person(id: 2, name: "Bob")
        ]
        // Save
        container.mainContext.insert(people[0])
        container.mainContext.insert(people[1])
        
        // Fetch
        let personFetch = FetchDescriptor<Person>()
        let persons = try container.mainContext.fetch(personFetch)
    
        #expect(persons.contains(people[0]))
        #expect(persons.contains(people[1]))
    }

}

