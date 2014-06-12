OSDCoreDataManager-Swift
========================

Core Data Manager in Swift

***

#### Example

```Swift

let path = ".../database.sqlite"
let managedModel = NSManagedObjectModel()...

let stack = OSDCoreDataStack(path: path, managedObjectModel: managedModel)
if !stack.connect() {
  println("Failed to connect!")
}

```
