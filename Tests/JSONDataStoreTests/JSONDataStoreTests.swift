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

@Model
class Author {
    var id: Int
    var name: String
    @Relationship(deleteRule: .cascade) var books: [Book] = []
    
    public init(id: Int, name: String, books: [Book] = []) {
        self.id = id
        self.name = name
        self.books = books
    }
}

@Model
class Book {
    var id: Int
    var title: String
    @Relationship var author: Author?
    
    public init(id: Int, title: String, author: Author? = nil) {
        self.id = id
        self.title = title
        self.author = author
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

    @Test("Save and fetch author with books")
    @MainActor
    func testAuthorBookRelationship() async throws {
        let fileURL = tempFileURL()
        defer { deleteFile(fileURL) }
        let config = JSONStoreConfiguration(name: "test", schema: Schema([Author.self, Book.self]), fileURL: fileURL)
        let container = try ModelContainer(for: Author.self, Book.self, configurations: config)

        // Create author and books
        let author = Author(id: 101, name: "Jane Austen")
        let book1 = Book(id: 201, title: "Pride and Prejudice")
        let book2 = Book(id: 202, title: "Sense and Sensibility")
        author.books = [book1, book2]
        book1.author = author
        book2.author = author
        
        // Save
        container.mainContext.insert(author)
        container.mainContext.insert(book1)
        container.mainContext.insert(book2)
        try container.mainContext.save()

        // Fetch
        let authorFetch = FetchDescriptor<Author>()
        let authors = try container.mainContext.fetch(authorFetch)
        #expect(authors.count == 1)
        let fetchedAuthor = try #require(authors.first)
        #expect(fetchedAuthor.books.count == 2)
        let titles = Set(fetchedAuthor.books.map { $0.title })
        #expect(titles == ["Pride and Prejudice", "Sense and Sensibility"])
        // Check book->author relationship
        let fetchedBook = try #require(fetchedAuthor.books.first)
        #expect(fetchedBook.author?.name == "Jane Austen")
    }
}
