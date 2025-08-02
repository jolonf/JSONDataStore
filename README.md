# JSONDataStore

At WWDC24 Apple introduced custom data stores for SwiftData and presented a JSONDataStore example in the session [Create a custom data store with SwiftData](https://www.youtube.com/watch?v=_t2NflA8AcI). However I couldn't find the code online so I've recreated it here.

JSONDataStore is a Swift package library which provides a custom data store where the SwiftData data store is a single JSON file.

## How to use

```swift
import SwiftData
import JSONDataStore

let configuration = JSONStoreConfiguration(schema: Schema([Trip.self]), url: fileURL)
let container = ModelContainer(for: Trip.self, configurations: configuration)
```

## Key classes

The following are the two main classes defined in the package:

```swift
public final class JSONStoreConfiguration: DataStoreConfiguration {
  typealias Store = JSONStore
  ...
}

public final class JSONStore: DataStore {
  typealias Configuration: JSONStoreConfiguration
  typealias Snapshot: DefaultSnapshot
  
  func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Self.Snapshot> where T : PersistentModel {
    // Read JSON file...
  }
  
  func save(_ request: DataStoreSaveChangesRequest<Self.Snapshot>) throws -> DataStoreSaveChangesResult<Self.Snapshot> {
    // Save JSON file...
  }
}
```
