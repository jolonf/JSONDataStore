import Testing
import Foundation
import SwiftData
@testable import JSONDataStore


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
    
    @Test("Inheritance")
    @MainActor
    func testInheritance() async throws {
        let fileURL = tempFileURL()
        defer { deleteFile(fileURL) }
        let config = JSONStoreConfiguration(name: "test", schema: Schema([App.self, Window.self, Component.self, Button.self, Field.self]), fileURL: fileURL)
        let container = try ModelContainer(for: App.self, Window.self, Component.self, Button.self, Field.self, configurations: config)

        let button = Button(name: "Button 1", label: "Click me")
        let field = Field(name: "Post code", value: "4213")
        let window = Window(title: "Main Window", children: [button, field])
        let app = App(name: "My App", windows: [window])
        
        container.mainContext.insert(button)
        container.mainContext.insert(field)
        container.mainContext.insert(window)
        container.mainContext.insert(app)
        
        try container.mainContext.save()

        // Fetch
        let appFetch = FetchDescriptor<App>()
        let apps = try container.mainContext.fetch(appFetch)
        #expect(apps.count == 1)
        
        let fetchedApp = try #require(apps.first)
        
        #expect(fetchedApp.windows.count == 1)
        
        #expect(fetchedApp.windows[0].children.count == 2)
        
        for app in apps {
            print("app.name: \(app.name)")
            for window in app.windows {
                print("  window.title: \(window.title)")
                for component in window.children {
                    print("    component.name: \(component.name)")
                    switch component {
                    case is Button:
                        print("      button.label: \((component as! Button).label)")
                    case is Field:
                        print("      field.value: \((component as! Field).value)")
                    default:
                        print("Just a regular old component")
                    }
                }
            }
        }
    }
    
    
}

// MARK: - SwiftData Models


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

@Model
class App {
    var name: String
    var windows: [Window]
    
    init(name: String, windows: [Window]) {
        self.name = name
        self.windows = windows
    }
}

@Model
class Window {
    var title: String
    var children: [Component]
    
    init(title: String, children: [Component]) {
        self.title = title
        self.children = children
    }
}

@Model
class Component {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

@Model
@available(iOS 26.0, macOS 26.0, *)
class Button: Component {
    var label: String
    
    init(name: String, label: String) {
        self.label = label
        super.init(name: name)
    }
}

@Model
@available(iOS 26.0, macOS 26.0, *)
class Field: Component {
    var value: String
    
    init(name: String, value: String) {
        self.value = value
        super.init(name: name)
    }
}
