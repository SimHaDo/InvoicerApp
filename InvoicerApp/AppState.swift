//
//  AppState.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

// AppState.swift
import SwiftUI
import UIKit

// MARK: - Persistable settings

struct AppSettings: Codable, Equatable {
    var paymentMethods: [PaymentMethod] = []
    var additionalNotes: String? = nil
}

final class AppState: ObservableObject {
    // MARK: Business data
    @Published var selectedTemplate: InvoiceTemplateDescriptor = TemplateCatalog.all.first!

    @Published var logoData: Data? = nil
    var logoImage: UIImage? { get { logoData.flatMap(UIImage.init(data:)) } set { logoData = newValue?.pngData() } }

    @Published var isPremium: Bool = false
    let freeInvoiceLimit: Int = 1
    var remainingFreeInvoices: Int { max(0, freeInvoiceLimit - invoices.count) }
    var canCreateInvoice: Bool { isPremium || remainingFreeInvoices > 0 }

    @Published var company: Company? { didSet { Storage.save(company, key: .company) } }

    @Published var customers: [Customer] = Storage.load([Customer].self, key: .customers, fallback: Mock.customers) {
        didSet { Storage.save(customers, key: .customers) }
    }
    @Published var products:  [Product]  = Storage.load([Product].self,  key: .products,  fallback: Mock.products)  {
        didSet { Storage.save(products, key: .products) }
    }
    @Published var invoices:  [Invoice]  = Storage.load([Invoice].self,  key: .invoices,  fallback: [])             {
        didSet { Storage.save(invoices, key: .invoices) }
    }

    // MARK: Settings (persisted)
    @Published var settings: AppSettings = Storage.load(AppSettings.self, key: .settings, fallback: .init()) {
        didSet { Storage.save(settings, key: .settings) }
    }
    func saveSettings() {
        Storage.save(settings, key: .settings)
        objectWillChange.send()
    }

    // Convenience proxy: чтобы старый код мог обращаться к app.paymentMethods
    var paymentMethods: [PaymentMethod] {
        get { settings.paymentMethods }
        set { settings.paymentMethods = newValue; saveSettings() }
    }
    func savePaymentMethods() { saveSettings() }

    // MARK: UI state
    @Published var preselectedCustomer: Customer? = nil
    @Published var preselectedLineItem: LineItem?
    @Published var preselectedItems: [LineItem]? = nil
    @Published var subscription: SubscriptionState = .freeViewOnly
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"

    init() {
        self.company = Storage.load(Company?.self, key: .company, fallback: nil)
    }
}
