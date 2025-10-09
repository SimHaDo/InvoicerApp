//
//  RootTabView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var app: AppState
    @State private var selectedTab: Tab = .invoices
    @State private var navigationPath = NavigationPath()
    @State private var shouldDismissMyInfo = false
    @State private var showMyInfo = false

    enum Tab: String, CaseIterable {
        case invoices = "Invoices"
        case customers = "Customers"
        case products = "Products"
        case analytics = "Analytics"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .invoices: return "banknote"
            case .customers: return "person.2"
            case .products: return "shippingbox"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad layout with NavigationSplitView
            NavigationSplitView {
                List(Tab.allCases, id: \.self) { tab in
                    Button(action: { 
                        selectedTab = tab
                        // Очищаем навигацию при переключении табов на iPad
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            navigationPath = NavigationPath()
                            shouldDismissMyInfo = true
                            showMyInfo = false
                            print("RootTabView: Tab switched to \(tab.rawValue), cleared navigation")
                        }
                    }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .navigationTitle("Invoice Maker PRO")
            } detail: {
                NavigationStack(path: $navigationPath) {
                    selectedView
                        .environment(\.shouldDismissMyInfo, shouldDismissMyInfo)
                        .onChange(of: shouldDismissMyInfo) { newValue in
                            if newValue {
                                shouldDismissMyInfo = false
                            }
                        }
                }
            }
        } else {
            // iPhone layout with TabView
            TabView(selection: $selectedTab) {
                InvoicesScreen()
                    .tabItem { Image(systemName: Tab.invoices.icon); Text(Tab.invoices.rawValue) }
                    .tag(Tab.invoices)

                CustomersScreen()
                    .tabItem { Image(systemName: Tab.customers.icon); Text(Tab.customers.rawValue) }
                    .tag(Tab.customers)

                ProductsScreen()
                    .tabItem { Image(systemName: Tab.products.icon); Text(Tab.products.rawValue) }
                    .tag(Tab.products)

                AnalyticsScreen()
                    .tabItem { Image(systemName: Tab.analytics.icon); Text(Tab.analytics.rawValue) }
                    .tag(Tab.analytics)

                SettingsTab()
                    .tabItem { Image(systemName: Tab.settings.icon); Text(Tab.settings.rawValue) }
                    .tag(Tab.settings)
            }
        }
    }
    
    @ViewBuilder
    private var selectedView: some View {
        if showMyInfo && selectedTab == .settings {
            MyInfoView()
                .environmentObject(app)
        } else {
            switch selectedTab {
            case .invoices:
                InvoicesScreen()
            case .customers:
                CustomersScreen()
            case .products:
                ProductsScreen()
            case .analytics:
                AnalyticsScreen()
            case .settings:
                SettingsTab()
                    .environment(\.showMyInfo, $showMyInfo)
            }
        }
    }
}

// MARK: - Environment Keys

private struct ShouldDismissMyInfoKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct ShowMyInfoKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var shouldDismissMyInfo: Bool {
        get { self[ShouldDismissMyInfoKey.self] }
        set { self[ShouldDismissMyInfoKey.self] = newValue }
    }
    
    var showMyInfo: Binding<Bool> {
        get { self[ShowMyInfoKey.self] }
        set { self[ShowMyInfoKey.self] = newValue }
    }
}
