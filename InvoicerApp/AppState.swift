//
//  AppState.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

// AppState.swift
import SwiftUI
import UIKit

// MARK: - Persistable settings (НОВОЕ)
struct AppSettings: Codable, Equatable {
    var paymentMethods: [PaymentMethod] = []
    var additionalNotes: String? = nil
}

// NOTE: Убедись, что в твоём enum StorageKey есть .settings.
// Если его нет, добавь:
// enum StorageKey: String { case company, customers, products, invoices, settings }

final class AppState: ObservableObject {
    // Business data
    @Published var selectedTemplate: InvoiceTemplateDescriptor = TemplateCatalog.all.first!
    @Published var logoData: Data? = nil
    var logoImage: UIImage? { get { logoData.flatMap(UIImage.init(data:)) } set { logoData = newValue?.pngData() } }

    @Published var isPremium: Bool = false
    let freeInvoiceLimit: Int = 1
    var remainingFreeInvoices: Int { max(0, freeInvoiceLimit - invoices.count) }
    var canCreateInvoice: Bool { isPremium || remainingFreeInvoices > 0 }

    @Published var company: Company? { didSet { Storage.save(company, key: .company) } }
    @Published var customers: [Customer] = Storage.load([Customer].self, key: .customers, fallback: Mock.customers) { didSet { Storage.save(customers, key: .customers) } }
    @Published var products:  [Product]  = Storage.load([Product].self,  key: .products,  fallback: Mock.products)  { didSet { Storage.save(products, key: .products) } }
    @Published var invoices:  [Invoice]  = Storage.load([Invoice].self,  key: .invoices,  fallback: [])             { didSet { Storage.save(invoices, key: .invoices) } }

    // Settings (НОВОЕ)
    @Published var settings: AppSettings = Storage.load(AppSettings.self, key: .settings, fallback: .init()) {
        didSet { Storage.save(settings, key: .settings) }
    }
    func saveSettings() {
        Storage.save(settings, key: .settings)
        objectWillChange.send()
    }

    // UI state
    @Published var preselectedCustomer: Customer? = nil
    @Published var preselectedLineItem: LineItem?
    @Published var preselectedItems: [LineItem]? = nil
    @Published var subscription: SubscriptionState = .freeViewOnly
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"

    init() {
        self.company = Storage.load(Company?.self, key: .company, fallback: nil)
    }
}
