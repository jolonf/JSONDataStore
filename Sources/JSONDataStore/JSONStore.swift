import Foundation
import SwiftData

/// The JSON-backed custom DataStore for SwiftData.
public final class JSONStore: DataStore {
    public typealias Configuration = JSONStoreConfiguration
    public typealias Snapshot = DefaultSnapshot

    public let configuration: Configuration
    public var name: String
    public var identifier: String
    public var schema: Schema
    
    public init(_ configuration: JSONStoreConfiguration, migrationPlan: (any SchemaMigrationPlan.Type)? = nil) throws {
        self.configuration = configuration
        self.name = configuration.name
        self.schema = configuration.schema!
        self.identifier = configuration.fileURL.lastPathComponent
    }

    public func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot> where T: PersistentModel {
        // TODO: Implement fetch logic (read from JSON file)
        throw NSError(domain: "JSONStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    public func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
        // TODO: Implement save logic (write to JSON file)
        throw NSError(domain: "JSONStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}
