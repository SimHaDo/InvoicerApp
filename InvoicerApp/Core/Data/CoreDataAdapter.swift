//
//  CoreDataAdapter.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import UIKit

/// Адаптер для интеграции Core Data с существующим AppState
@MainActor
final class CoreDataAdapter: ObservableObject {
    static let shared = CoreDataAdapter()
    
    private let coreDataStack = CoreDataStack.shared
    
    @Published var isCloudKitAvailable: Bool = false
    @Published var syncError: String? = nil
    @Published var lastSyncDate: Date? = nil
    
    private init() {
        // Initialize with default values
        isCloudKitAvailable = false
        syncError = nil
        lastSyncDate = nil
        
        // Check if running on simulator
        #if targetEnvironment(simulator)
        print("CoreDataAdapter: Running on simulator - CloudKit will not work")
        syncError = "CloudKit не работает в симуляторе. Используйте реальное устройство для тестирования синхронизации."
        #else
        // Check CloudKit status asynchronously with delay to ensure container is loaded
        Task { @MainActor in
            // Wait a bit for the container to fully initialize
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            print("CoreDataAdapter: Checking CloudKit status...")
            let available = await coreDataStack.isCloudKitAvailable()
            print("CoreDataAdapter: CloudKit status result: \(available)")
            self.isCloudKitAvailable = available
            if !available {
                self.syncError = "CloudKit недоступен. Проверьте подключение к iCloud."
                print("CoreDataAdapter: CloudKit not available, setting error message")
            } else {
                print("CoreDataAdapter: CloudKit is available!")
            }
        }
        #endif
        
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: coreDataStack.viewContext.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.lastSyncDate = Date()
                print("CoreDataAdapter: Remote change detected, lastSyncDate updated")
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Conversion Helpers
    
    func convertToCoreDataCompany(_ company: Company) -> CompanyEntity {
        let context = coreDataStack.viewContext
        let coreDataCompany = CompanyEntity(context: context)
        
        coreDataCompany.id = company.id
        coreDataCompany.name = company.name
        coreDataCompany.email = company.email
        coreDataCompany.phone = company.phone
        coreDataCompany.website = company.website
        coreDataCompany.addressLine1 = company.address.line1
        coreDataCompany.addressLine2 = company.address.line2
        coreDataCompany.city = company.address.city
        coreDataCompany.state = company.address.state
        coreDataCompany.zip = company.address.zip
        coreDataCompany.country = company.address.country
        coreDataCompany.logoData = company.logoData
        coreDataCompany.lastModified = Date()
        
        return coreDataCompany
    }
    
    func convertFromCoreDataCompany(_ coreDataCompany: CompanyEntity) -> Company {
        var company = Company()
        company.id = coreDataCompany.id ?? UUID()
        company.name = coreDataCompany.name ?? ""
        company.email = coreDataCompany.email ?? ""
        company.phone = coreDataCompany.phone ?? ""
        company.website = coreDataCompany.website
        company.address.line1 = coreDataCompany.addressLine1 ?? ""
        company.address.line2 = coreDataCompany.addressLine2 ?? ""
        company.address.city = coreDataCompany.city ?? ""
        company.address.state = coreDataCompany.state ?? ""
        company.address.zip = coreDataCompany.zip ?? ""
        company.address.country = coreDataCompany.country ?? ""
        company.logoData = coreDataCompany.logoData
        
        return company
    }
    
    func convertToCoreDataCustomer(_ customer: Customer) -> CustomerEntity {
        let context = coreDataStack.viewContext
        let coreDataCustomer = CustomerEntity(context: context)
        
        coreDataCustomer.id = customer.id
        coreDataCustomer.name = customer.name
        coreDataCustomer.email = customer.email
        coreDataCustomer.phone = customer.phone
        coreDataCustomer.organization = customer.organization
        coreDataCustomer.status = customer.status.rawValue
        coreDataCustomer.billingDetails = customer.billingDetails
        coreDataCustomer.addressLine1 = customer.address.line1
        coreDataCustomer.addressLine2 = customer.address.line2
        coreDataCustomer.city = customer.address.city
        coreDataCustomer.state = customer.address.state
        coreDataCustomer.zip = customer.address.zip
        coreDataCustomer.country = customer.address.country
        coreDataCustomer.lastModified = Date()
        
        return coreDataCustomer
    }
    
    func convertFromCoreDataCustomer(_ coreDataCustomer: CustomerEntity) -> Customer {
        var customer = Customer()
        customer.id = coreDataCustomer.id ?? UUID()
        customer.name = coreDataCustomer.name ?? ""
        customer.email = coreDataCustomer.email ?? ""
        customer.phone = coreDataCustomer.phone ?? ""
        customer.organization = coreDataCustomer.organization
        customer.status = CustomerStatus(rawValue: coreDataCustomer.status ?? "active") ?? .active
        customer.billingDetails = coreDataCustomer.billingDetails
        customer.address.line1 = coreDataCustomer.addressLine1 ?? ""
        customer.address.line2 = coreDataCustomer.addressLine2 ?? ""
        customer.address.city = coreDataCustomer.city ?? ""
        customer.address.state = coreDataCustomer.state ?? ""
        customer.address.zip = coreDataCustomer.zip ?? ""
        customer.address.country = coreDataCustomer.country ?? ""
        
        return customer
    }
    
    func convertToCoreDataProduct(_ product: Product) -> ProductEntity {
        let context = coreDataStack.viewContext
        let coreDataProduct = ProductEntity(context: context)
        
        coreDataProduct.id = product.id
        coreDataProduct.name = product.name
        coreDataProduct.details = product.details
        coreDataProduct.rate = NSDecimalNumber(decimal: product.rate)
        coreDataProduct.category = product.category
        coreDataProduct.lastModified = Date()
        
        return coreDataProduct
    }
    
    func convertFromCoreDataProduct(_ coreDataProduct: ProductEntity) -> Product {
        return Product(
            id: coreDataProduct.id ?? UUID(),
            name: coreDataProduct.name ?? "",
            details: coreDataProduct.details ?? "",
            rate: (coreDataProduct.rate as Decimal?) ?? 0,
            category: coreDataProduct.category ?? ""
        )
    }
    
    func convertToCoreDataInvoice(_ invoice: Invoice) -> InvoiceEntity {
        let context = coreDataStack.viewContext
        let coreDataInvoice = InvoiceEntity(context: context)
        
        coreDataInvoice.id = invoice.id
        coreDataInvoice.number = invoice.number
        coreDataInvoice.status = invoice.status.rawValue
        coreDataInvoice.issueDate = invoice.issueDate
        coreDataInvoice.dueDate = invoice.dueDate
        coreDataInvoice.currency = invoice.currency
        coreDataInvoice.paymentNotes = invoice.paymentNotes
        coreDataInvoice.taxRate = NSDecimalNumber(decimal: invoice.taxRate)
        coreDataInvoice.taxType = invoice.taxType.rawValue
        coreDataInvoice.discountValue = NSDecimalNumber(decimal: invoice.discountValue)
        coreDataInvoice.discountType = invoice.discountType.rawValue
        coreDataInvoice.isDiscountEnabled = NSNumber(value: invoice.isDiscountEnabled)
        coreDataInvoice.totalPaid = NSDecimalNumber(decimal: invoice.totalPaid)
        coreDataInvoice.lastModified = Date()
        
        // Store company and customer IDs
        coreDataInvoice.companyId = invoice.company.id
        coreDataInvoice.customerId = invoice.customer.id
        
        // Store line items as JSON data
        if let itemsData = try? JSONEncoder().encode(invoice.items) {
            coreDataInvoice.itemsData = itemsData
        }
        
        // Store payment methods as JSON data
        if let paymentMethodsData = try? JSONEncoder().encode(invoice.paymentMethods) {
            coreDataInvoice.paymentMethodsData = paymentMethodsData
        }
        
        return coreDataInvoice
    }
    
    func convertFromCoreDataInvoice(_ coreDataInvoice: InvoiceEntity) -> Invoice {
        // Create a minimal invoice - we'll need to set company and customer separately
        let invoice = Invoice(
            number: coreDataInvoice.number ?? "",
            issueDate: coreDataInvoice.issueDate ?? Date(),
            company: Company(), // Will be set by caller
            customer: Customer(), // Will be set by caller
            items: []
        )
        
        var mutableInvoice = invoice
        mutableInvoice.id = coreDataInvoice.id ?? UUID()
        mutableInvoice.status = Invoice.Status(rawValue: coreDataInvoice.status ?? "draft") ?? .draft
        mutableInvoice.dueDate = coreDataInvoice.dueDate
        mutableInvoice.currency = coreDataInvoice.currency ?? "USD"
        mutableInvoice.paymentNotes = coreDataInvoice.paymentNotes
        mutableInvoice.taxRate = (coreDataInvoice.taxRate as Decimal?) ?? 0
        mutableInvoice.taxType = TaxType(rawValue: coreDataInvoice.taxType ?? "percentage") ?? .percentage
        mutableInvoice.discountValue = (coreDataInvoice.discountValue as Decimal?) ?? 0
        mutableInvoice.discountType = DiscountType(rawValue: coreDataInvoice.discountType ?? "percentage") ?? .percentage
        mutableInvoice.isDiscountEnabled = coreDataInvoice.isDiscountEnabled?.boolValue ?? false
        mutableInvoice.totalPaid = (coreDataInvoice.totalPaid as Decimal?) ?? 0
        
        // Convert line items from JSON data
        if let itemsData = coreDataInvoice.itemsData,
           let items = try? JSONDecoder().decode([LineItem].self, from: itemsData) {
            mutableInvoice.items = items
        }
        
        // Convert payment methods from JSON data
        if let paymentMethodsData = coreDataInvoice.paymentMethodsData,
           let paymentMethods = try? JSONDecoder().decode([PaymentMethod].self, from: paymentMethodsData) {
            mutableInvoice.paymentMethods = paymentMethods
        }
        
        return mutableInvoice
    }
    
    func convertToCoreDataAppSettings(_ settings: AppSettings) -> AppSettingsEntity {
        let context = coreDataStack.viewContext
        let coreDataSettings = AppSettingsEntity(context: context)
        
        coreDataSettings.id = UUID()
        coreDataSettings.additionalNotes = settings.additionalNotes
        coreDataSettings.lastModified = Date()
        
        // Store payment methods as JSON data
        if let paymentMethodsData = try? JSONEncoder().encode(settings.paymentMethods) {
            coreDataSettings.paymentMethodsData = paymentMethodsData
        }
        
        return coreDataSettings
    }
    
    func convertFromCoreDataAppSettings(_ coreDataSettings: AppSettingsEntity) -> AppSettings {
        var settings = AppSettings()
        settings.additionalNotes = coreDataSettings.additionalNotes
        
        // Convert payment methods from JSON data
        if let paymentMethodsData = coreDataSettings.paymentMethodsData,
           let paymentMethods = try? JSONDecoder().decode([PaymentMethod].self, from: paymentMethodsData) {
            settings.paymentMethods = paymentMethods
        }
        
        return settings
    }
    
    // MARK: - Save Methods
    
    func saveCompany(_ company: Company) {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", company.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let existingCompany = results.first {
                // Update existing
                existingCompany.name = company.name
                existingCompany.email = company.email
                existingCompany.phone = company.phone
                existingCompany.website = company.website
                existingCompany.addressLine1 = company.address.line1
                existingCompany.addressLine2 = company.address.line2
                existingCompany.city = company.address.city
                existingCompany.state = company.address.state
                existingCompany.zip = company.address.zip
                existingCompany.country = company.address.country
                existingCompany.logoData = company.logoData
                existingCompany.lastModified = Date()
                print("CoreDataAdapter: Updated existing company with logo data: \(company.logoData?.count ?? 0) bytes")
            } else {
                // Create new
                let newCompany = convertToCoreDataCompany(company)
                print("CoreDataAdapter: Created new company with logo data: \(company.logoData?.count ?? 0) bytes")
            }
            coreDataStack.save()
            print("CoreDataAdapter: Company saved successfully")
        } catch {
            print("Error saving company: \(error)")
        }
    }
    
    func saveCustomers(_ customers: [Customer]) {
        let context = coreDataStack.viewContext
        
        // Clear existing customers
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: CustomerEntity.fetchRequest())
        try? context.execute(deleteRequest)
        
        // Save new customers
        for customer in customers {
            _ = convertToCoreDataCustomer(customer)
        }
        
        coreDataStack.save()
    }
    
    func saveProducts(_ products: [Product]) {
        let context = coreDataStack.viewContext
        
        // Clear existing products
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: ProductEntity.fetchRequest())
        try? context.execute(deleteRequest)
        
        // Save new products
        for product in products {
            _ = convertToCoreDataProduct(product)
        }
        
        coreDataStack.save()
    }
    
    func saveInvoices(_ invoices: [Invoice]) {
        let context = coreDataStack.viewContext
        
        // Clear existing invoices
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: InvoiceEntity.fetchRequest())
        try? context.execute(deleteRequest)
        
        // Save new invoices
        for invoice in invoices {
            _ = convertToCoreDataInvoice(invoice)
        }
        
        coreDataStack.save()
    }
    
    func saveAppSettings(_ settings: AppSettings) {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let existingSettings = results.first {
                // Update existing
                existingSettings.additionalNotes = settings.additionalNotes
                existingSettings.lastModified = Date()
            } else {
                // Create new
                _ = convertToCoreDataAppSettings(settings)
            }
            coreDataStack.save()
        } catch {
            print("Error saving app settings: \(error)")
        }
    }
    
    // MARK: - Fetch Methods
    
    func fetchCompany() -> Company? {
        let request: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            return results.first.map(convertFromCoreDataCompany)
        } catch {
            print("Error fetching company: \(error)")
            return nil
        }
    }
    
    func fetchCustomers() -> [Customer] {
        let request: NSFetchRequest<CustomerEntity> = CustomerEntity.fetchRequest()
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            return results.map(convertFromCoreDataCustomer)
        } catch {
            print("Error fetching customers: \(error)")
            return []
        }
    }
    
    func fetchProducts() -> [Product] {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            return results.map(convertFromCoreDataProduct)
        } catch {
            print("Error fetching products: \(error)")
            return []
        }
    }
    
    func fetchInvoices() -> [Invoice] {
        let request: NSFetchRequest<InvoiceEntity> = InvoiceEntity.fetchRequest()
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            return results.map(convertFromCoreDataInvoice)
        } catch {
            print("Error fetching invoices: \(error)")
            return []
        }
    }
    
    func fetchAppSettings() -> AppSettings? {
        let request: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            return results.first.map(convertFromCoreDataAppSettings)
        } catch {
            print("Error fetching app settings: \(error)")
            return AppSettings()
        }
    }
    
    // MARK: - Migration
    
    func migrateFromUserDefaults() {
        // Migrate existing data from UserDefaults to Core Data
        // Company
        if let company = Storage.load(Company?.self, key: .company, fallback: nil) {
            saveCompany(company)
            Storage.save(nil as Company?, key: .company) // Clear from UserDefaults
        }
        
        // Customers
        let customers = Storage.load([Customer].self, key: .customers, fallback: [])
        if !customers.isEmpty {
            saveCustomers(customers)
            Storage.save([] as [Customer], key: .customers) // Clear from UserDefaults
        }
        
        // Products
        let products = Storage.load([Product].self, key: .products, fallback: [])
        if !products.isEmpty {
            saveProducts(products)
            Storage.save([] as [Product], key: .products) // Clear from UserDefaults
        }
        
        // Invoices
        let invoices = Storage.load([Invoice].self, key: .invoices, fallback: [])
        if !invoices.isEmpty {
            saveInvoices(invoices)
            Storage.save([] as [Invoice], key: .invoices) // Clear from UserDefaults
        }
        
        // Settings
        let settings = Storage.load(AppSettings.self, key: .settings, fallback: .init())
        saveAppSettings(settings)
        Storage.save(AppSettings(), key: .settings) // Clear from UserDefaults
    }
    
    // MARK: - Sync Methods
    
    func forceSync() {
        coreDataStack.forceSync()
    }
    
    /// Принудительная синхронизация логотипа компании
    func syncCompanyLogo(_ logoData: Data?) {
        guard let company = fetchCompany() else {
            print("CoreDataAdapter: No company found to sync logo")
            return
        }
        
        // Check logo size (CloudKit has limits on binary data)
        if let logoData = logoData {
            let maxSize = 10 * 1024 * 1024 // 10MB limit for CloudKit
            if logoData.count > maxSize {
                print("CoreDataAdapter: Warning - Logo size (\(logoData.count) bytes) exceeds CloudKit limit (\(maxSize) bytes)")
                // Try to compress the image
                if let image = UIImage(data: logoData),
                   let compressedData = image.jpegData(compressionQuality: 0.5) {
                    print("CoreDataAdapter: Compressed logo from \(logoData.count) to \(compressedData.count) bytes")
                    var updatedCompany = company
                    updatedCompany.logoData = compressedData
                    saveCompany(updatedCompany)
                } else {
                    print("CoreDataAdapter: Failed to compress logo, skipping sync")
                    return
                }
            } else {
                var updatedCompany = company
                updatedCompany.logoData = logoData
                saveCompany(updatedCompany)
            }
        } else {
            var updatedCompany = company
            updatedCompany.logoData = nil
            saveCompany(updatedCompany)
        }
        
        // Force sync to CloudKit
        forceSync()
        print("CoreDataAdapter: Company logo synced to CloudKit: \(logoData?.count ?? 0) bytes")
    }
    
    /// Проверка статуса синхронизации CloudKit
    func checkCloudKitSyncStatus() async -> Bool {
        return await coreDataStack.isCloudKitAvailable()
    }
}