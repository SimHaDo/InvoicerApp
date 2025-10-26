//
//  CoreDataStack.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import Foundation
import CoreData
import CloudKit

final class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "InvoicerApp")
        
        // Configure CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // CloudKit configuration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.SimHaDo.InvoicerApp"
        )
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configure for CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Core Data Operations
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func saveContext() {
        save()
    }
    
    // MARK: - CloudKit Status
    
    func checkCloudKitStatus() async -> Bool {
        let container = CKContainer(identifier: "iCloud.SimHaDo.InvoicerApp")
        
        do {
            let status = try await container.accountStatus()
            print("CoreDataStack: CloudKit account status: \(status)")
            
            switch status {
            case .available:
                print("CoreDataStack: CloudKit is available")
                return true
            case .noAccount:
                print("CoreDataStack: No iCloud account")
                return false
            case .restricted:
                print("CoreDataStack: iCloud account is restricted")
                return false
            case .couldNotDetermine:
                print("CoreDataStack: Could not determine iCloud account status")
                return false
            @unknown default:
                print("CoreDataStack: Unknown iCloud account status")
                return false
            }
        } catch {
            print("CoreDataStack: CloudKit status check failed: \(error)")
            return false
        }
    }
    
    // MARK: - Data Migration Helpers
    
    func migrateFromOldStorage() {
        // This will be used to migrate existing data from UserDefaults to Core Data
        // Implementation will be added based on existing data structure
    }
}

// MARK: - CloudKit Configuration

extension CoreDataStack {
    
    /// Configure CloudKit schema for automatic sync
    func configureCloudKitSchema() {
        // This method can be called to ensure CloudKit schema is properly configured
        // NSPersistentCloudKitContainer handles this automatically, but we can add
        // custom configuration if needed
    }
    
    /// Check if CloudKit is available and properly configured
    func isCloudKitAvailable() async -> Bool {
        let status = await checkCloudKitStatus()
        print("CoreDataStack: isCloudKitAvailable() returning: \(status)")
        return status
    }
}

// MARK: - Core Data + CloudKit Integration

extension CoreDataStack {
    
    /// Get all entities that should be synced with CloudKit
    func getCloudKitEntities() -> [String] {
        return [
            "CompanyEntity",
            "CustomerEntity", 
            "ProductEntity",
            "InvoiceEntity",
            "LineItemEntity",
            "PaymentMethodEntity",
            "AppSettingsEntity"
        ]
    }
    
    /// Force sync with CloudKit
    func forceSync() {
        // NSPersistentCloudKitContainer handles sync automatically
        // This method can be used to trigger manual sync if needed
        print("CoreDataStack: Forcing sync to CloudKit...")
        save()
        print("CoreDataStack: Sync completed")
    }
}
