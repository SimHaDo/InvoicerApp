//
//  AppState.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Persistable settings

struct AppSettings: Codable, Equatable {
    var paymentMethods: [PaymentMethod] = []
    var additionalNotes: String? = nil
}

// MARK: - Local keys (UserDefaults)

private enum PrefKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let selectedTemplateID     = "selectedTemplateID"
    static let isProSubscription      = "isProSubscription"
}

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {

    // MARK: Business data

    @Published var selectedTemplate: CompleteInvoiceTemplate = 
        CompleteInvoiceTemplate(template: TemplateCatalog.all.first!, theme: TemplateCatalog.themes.first!)

    @Published var logoData: Data? = Storage.loadLogo() {
        didSet { 
            print("AppState: Logo data changed, saving...")
            Storage.saveLogo(logoData)
        }
    }
    var logoImage: UIImage? {
        get { 
            guard let data = logoData else { return nil }
            return UIImage(data: data)
        }
        set { 
            logoData = newValue?.pngData()
        }
    }

    @Published var isPremium: Bool = false

    let freeInvoiceLimit: Int = 1
    var remainingFreeInvoices: Int { max(0, freeInvoiceLimit - invoices.count) }
    var canCreateInvoice: Bool { isPremium || remainingFreeInvoices > 0 }

    @Published var company: Company? {
        didSet { Storage.save(company, key: .company) }
    }

    @Published var customers: [Customer] =
        Storage.load([Customer].self, key: .customers, fallback: Mock.customers) {
        didSet { 
            print("AppState: Saving \(customers.count) customers")
            Storage.save(customers, key: .customers) 
        }
    }

    @Published var products: [Product] =
        Storage.load([Product].self, key: .products, fallback: Mock.products) {
        didSet { 
            print("AppState: Saving \(products.count) products")
            Storage.save(products, key: .products) 
        }
    }

    @Published var invoices: [Invoice] =
        Storage.load([Invoice].self, key: .invoices, fallback: []) {
        didSet { Storage.save(invoices, key: .invoices) }
    }

    // MARK: Settings (persisted)

    @Published var settings: AppSettings =
        Storage.load(AppSettings.self, key: .settings, fallback: .init()) {
        didSet { Storage.save(settings, key: .settings) }
    }

    func saveSettings() {
        Storage.save(settings, key: .settings)
        objectWillChange.send()
    }

    // proxy для совместимости
    var paymentMethods: [PaymentMethod] {
        get { settings.paymentMethods }
        set { settings.paymentMethods = newValue; saveSettings() }
    }
    func savePaymentMethods() { saveSettings() }
    
    // MARK: - Debug Functions
    
    func loadTestData() {
        print("AppState: Loading test data...")
        customers = Mock.customers
        products = Mock.products
        print("AppState: Loaded \(customers.count) customers, \(products.count) products")
    }

    // MARK: UI state

    @Published var preselectedCustomer: Customer? = nil
    @Published var preselectedLineItem: LineItem?
    @Published var preselectedItems: [LineItem]? = nil
    @Published var subscription: SubscriptionState = .freeViewOnly
    @Published var currency: String = Locale.current.currency?.identifier ?? "USD"

    /// Онбординг завершён?
    @Published var hasCompletedOnboarding: Bool =
        UserDefaults.standard.bool(forKey: PrefKey.hasCompletedOnboarding)

    // MARK: Internals

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init() {
        print("AppState: Initializing...")
        self.company = Storage.load(Company?.self, key: .company, fallback: nil)
        print("AppState: Loaded \(customers.count) customers, \(products.count) products")

        // выбранный шаблон — сначала iCloud, затем локаль
        if let id = CloudSync.shared.string(.selectedTemplateID)
            ?? UserDefaults.standard.string(forKey: PrefKey.selectedTemplateID),
           let found = TemplateCatalog.all.first(where: { $0.id == id }) {
            selectedTemplate = CompleteInvoiceTemplate(template: found, theme: TemplateCatalog.themes.first!)
        }

        // про-флаг — iCloud / локаль
        let proKVS = CloudSync.shared.bool(.isProSubscriber) // CloudSync.bool -> Bool
        let proUD  = UserDefaults.standard.bool(forKey: PrefKey.isProSubscription)
        self.isPremium = proUD || proKVS

        // подписки от менеджера подписок
        SubscriptionManager.shared.$isPro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in
                guard let self else { return }
                self.isPremium = val
                self.persistProFlag(val)
            }
            .store(in: &cancellables)

        // слушаем внешние изменения iCloud KVS
        // Temporarily disabled CloudSync to avoid entitlement errors
        // NotificationCenter.default.addObserver(
        //     forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
        //     object: NSUbiquitousKeyValueStore.default,
        //     queue: .main
        // ) { [weak self] _ in
        //     // Класс @MainActor, поэтому вызываем на мейне безопасно
        //     Task { @MainActor in self?.pullFromCloud() }
        // }

        // CloudSync.shared.synchronize()
    }

    // MARK: Cloud sync (KVS)

    private func pullFromCloud() {
        // isPro
        let isProCloud = CloudSync.shared.bool(.isProSubscriber)
        if isPremium != isProCloud {
            isPremium = isProCloud
            UserDefaults.standard.set(isProCloud, forKey: PrefKey.isProSubscription)
        }

        // template
        if let tmplID = CloudSync.shared.string(.selectedTemplateID),
           let found = TemplateCatalog.all.first(where: { $0.id == tmplID }) {
            if selectedTemplate.id != found.id {
                selectedTemplate = CompleteInvoiceTemplate(template: found, theme: selectedTemplate.theme)
                UserDefaults.standard.set(tmplID, forKey: PrefKey.selectedTemplateID)
            }
        }

        // onboarding
        let onboarded = CloudSync.shared.bool(.hasCompletedOnboarding)
        if hasCompletedOnboarding != onboarded {
            hasCompletedOnboarding = onboarded
            UserDefaults.standard.set(onboarded, forKey: PrefKey.hasCompletedOnboarding)
        }
    }

    func markOnboardingCompleted() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: PrefKey.hasCompletedOnboarding)
        CloudSync.shared.set(true, for: .hasCompletedOnboarding)
    }

    func persistSelectedTemplate() {
        let id = selectedTemplate.id
        UserDefaults.standard.set(id, forKey: PrefKey.selectedTemplateID)
        CloudSync.shared.set(id, for: .selectedTemplateID)
    }

    func persistProFlag(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: PrefKey.isProSubscription)
        CloudSync.shared.set(value, for: .isProSubscriber)
    }
}
