import Foundation
import CoreData

struct ConstainerMigrationManager {

    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func migrateIfNeeded() throws {
        guard needsMigration else {
            return
        }

        DDLogWarn("⚠️ [CoreDataManager] Migration required for persistent store")

        let versionInfo = objectModel.entityVersionHashesByName
            .keys
            .sorted()

        try CoreDataIterativeMigrator.iterativeMigrate(
            sourceStore: storeURL,
            storeType: NSSQLiteStoreType,
            to: objectModel,
            using: versionInfo
        )
    }

    var needsMigration: Bool {
        guard FileManager.default.fileExists(atPath: storePath) else {
            DDLogInfo("No store exists at URL \(storeURL).  Skipping migration.")
            return false
        }

        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )

            /// If the ManagedObjectModel's configuration is compatible with this store, no further action is necessary – they two are in sync
            return objectModel.isConfiguration(withName: "Default", compatibleWithStoreMetadata: metadata)

        } catch let err {
            DDLogInfo("Error fetching persistent store metadata: \(err)")
            return false
        }
    }

}
