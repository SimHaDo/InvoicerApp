//
//  AppState.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - AppState.swift
final class AppState: ObservableObject {
    // Business data
    @Published var company: Company? { didSet { Storage.save(company, key: .company) } }
    @Published var customers: [Customer] = Storage.load([Customer].self, key: .customers, fallback: Mock.customers) { didSet { Storage.save(customers, key: .customers) } }
    @Published var products: [Product]  = Storage.load([Product].self,  key: .products,  fallback: Mock.products)  { didSet { Storage.save(products, key: .products) } }
    @Published var invoices: [Invoice]  = Storage.load([Invoice].self,  key: .invoices,  fallback: [])            { didSet { Storage.save(invoices, key: .invoices) } }
    @Published var preselectedCustomer: Customer? = nil
    // UI state
    @Published var preselectedItems: [LineItem]? = nil
    @Published var subscription: SubscriptionState = .freeViewOnly
    @Published var selectedTemplate: InvoiceTemplate? = nil
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"
    init() { self.company = Storage.load(Company?.self, key: .company, fallback: nil) }
}
