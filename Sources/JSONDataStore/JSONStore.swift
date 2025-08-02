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
        // Don't support predicates or sort
        if request.descriptor.predicate != nil {
            throw DataStoreError.preferInMemoryFilter
        } else if request.descriptor.sortBy.count > 0 {
            throw DataStoreError.preferInMemorySort
        }
        
        let snapshots = try read()

        return DataStoreFetchResult(descriptor: request.descriptor, fetchedSnapshots: snapshots)
    }

    public func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
        
        var snapshotsByIdentifier = [PersistentIdentifier: DefaultSnapshot]()
        
        try self.read().forEach { snapshotsByIdentifier[$0.persistentIdentifier] = $0 }
        
        // Temporary to permanent identifier map
        var remappedIdentifiers = [PersistentIdentifier: PersistentIdentifier]()
        
        for snapshot in request.inserted {
            let entityName = snapshot.persistentIdentifier.entityName
            let permanentIdentifier = try PersistentIdentifier.identifier(for: identifier, entityName: entityName, primaryKey: UUID())
            let snapshotCopy = snapshot.copy(persistentIdentifier: permanentIdentifier)
            remappedIdentifiers[snapshot.persistentIdentifier] = permanentIdentifier
            snapshotsByIdentifier[permanentIdentifier] = snapshotCopy
        }
        
        for snapshot in request.updated {
            snapshotsByIdentifier[snapshot.persistentIdentifier] = snapshot
        }
        
        for snapshot in request.deleted {
            snapshotsByIdentifier[snapshot.persistentIdentifier] = nil
        }
        
        let snapshots = snapshotsByIdentifier.values.map { $0 }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(snapshots)
        try jsonData.write(to: configuration.fileURL)
        
        return DataStoreSaveChangesResult(for: self.identifier, remappedIdentifiers: remappedIdentifiers)
    }
    
    func read() throws -> [DefaultSnapshot] {
        // If file doesn't exist return an empty array, as save always attempts to read first
        if FileManager.default.fileExists(atPath: configuration.fileURL.path()) {
            let decoder = JSONDecoder()
            return try decoder.decode([DefaultSnapshot].self, from: try Data(contentsOf: configuration.fileURL))
        } else {
            return []
        }
    }
}
