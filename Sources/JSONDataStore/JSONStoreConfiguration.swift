import Foundation
import SwiftData

/// The configuration object for JSONStore, specifying the backing file and schema to use.
public final class JSONStoreConfiguration: DataStoreConfiguration {
    public typealias Store = JSONStore

    public var name: String
    public var schema: Schema?
    public let fileURL: URL

    public init(name: String, schema: Schema? = nil, fileURL: URL) {
        self.name = name
        self.schema = schema
        self.fileURL = fileURL
    }
    
    public static func == (lhs: JSONStoreConfiguration, rhs: JSONStoreConfiguration) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
}
