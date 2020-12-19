import CoreData

/// Handles the core data stack for the whole app
class CoreDataManager {

    typealias CoreDataInitializationCallback = (Result<(), Error>) -> Void

    typealias CoreDataWriteBlock = (NSManagedObjectContext) -> Void

    typealias CoreDataWriteCompletionBlock = (Result<(), Error>) -> Void

    private let modelName = "WordPress"

    private let container: NSPersistentContainer

    /// Only for tests, do not use this method directly
    init() throws {
        ValueTransformer.registerCustomTransformers()

        let container = NSPersistentContainer(name: modelName)

        try CoreDataMigrationManager(storePath: container.storeUrl, objectModel: container.managedObjectModel)
            .migrateIfNeeded(modelURL: container.modelUrl)

        let storeDescription = NSPersistentStoreDescription(url: container.modelUrl)
        storeDescription.shouldMigrateStoreAutomatically = false
        storeDescription.shouldAddStoreAsynchronously = true /// Don't tie up the main thread doing DB initialization – we get a callback anyway
        container.persistentStoreDescriptions = [storeDescription]

        self.container = container
    }

    func loadPersistentStores(callback: @escaping CoreDataInitializationCallback) {
        container.loadPersistentStores { [weak self] (store, error) in
            guard self != nil else {
                return
            }

            if let error = error {
                callback(.failure(error))
            }
        }
    }

    private func handleLoadPersistentStoresError(error: Error) {
        DDLogError("⛔️ [CoreDataManager] loadPersistentStore failed. Attempting to recover... \(error)")
        self.sentryStartupError.add(error: error)
    }

    var readContext: NSManagedObjectContext {
        return container.viewContext
    }

    func performChangesAndSave(_ changes:(NSManagedObjectContext) -> Void) -> Result<Void, Error> {

        var error: Error?

        let writerContext = container.newBackgroundContext()
        writerContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writerContext.performAndWait {
            changes(writerContext)

            do {
                try writerContext.save()
            } catch let err {
                error = err
            }
        }

        if let error = error {
            return .failure(error)
        }

        return .success(())
    }

    func performChangesAndSave(_ callback: @escaping CoreDataWriteBlock, onCompletion: CoreDataWriteCompletionBlock?) {
        let writerContext = container.newBackgroundContext()
        writerContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writerContext.perform {
            callback(writerContext)

            do {
                try self.saveChanges(to: writerContext)
                onCompletion?(.success(()))
            } catch let err {
                onCompletion?(.failure(err))
            }
        }
    }

    private func saveChanges(to context: NSManagedObjectContext) throws {

        guard context.hasChanges else {
            return
        }

        try context.save()
    }

    // Error handling
    private lazy var sentryStartupError: SentryStartupEvent = {
        return SentryStartupEvent()
    }()
}

extension NSPersistentContainer {
    var modelUrl: URL {
        Bundle.main.url(forResource: name, withExtension: "momd")!
    }

    var storeUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name + ".sqlite")
    }
}
