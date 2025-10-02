//
//  SettingsTab.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//


import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {

                // MARK: - My Info (company + logo + payment methods)
                Section("My Info") {
                    NavigationLink {
                        MyInfoView() // ← отдельный экран, где редактируется компания/логотип/методы оплаты
                            .environmentObject(app)
                    } label: {
                        HStack(spacing: 12) {
                            // мини-превью логотипа
                            if let img = app.logoImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.06))
                                    .frame(width: 36, height: 36)
                                    .overlay(Text("•").foregroundStyle(.secondary))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                if let c = app.company, !c.name.isEmpty {
                                    Text(c.name).font(.headline)
                                    if !c.email.isEmpty {
                                        Text(c.email).font(.caption).foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("Set up your company").font(.headline)
                                    Text("Name, email, address, logo").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // MARK: - Account
                Section("Account") {
                    HStack {
                        Text("Pro Status")
                        Spacer()
                        Text(app.isPremium ? "Active" : "Free")
                            .foregroundStyle(app.isPremium ? .green : .secondary)
                    }

                    Button("Restore Purchases") {
                        Task { try? await SubscriptionManager.shared.restore() }
                    }
                }

                // MARK: - Data
                Section("Data") {
                    Button("Export All Data") {
                        // TODO: экспорт JSON/PDF
                        print("Export tapped")
                    }
                    Button("Reset Local Data") {
                        // TODO: очистка локального состояния/хранилищ
                        print("Reset tapped")
                    }
                    .foregroundColor(.red)
                }

                // MARK: - Support
                Section("Support") {
                    Button("Contact Support") {
                        if let url = URL(string: "mailto:dd925648@gmail.com") {
                            openURL(url)
                        }
                    }
                    Button("Rate on App Store") {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review") {
                            openURL(url)
                        }
                    }
                }

                // MARK: - Legal
                Section("Legal") {
                    Button("Privacy Policy") {
                        openURL(URL(string: "https://simhado.github.io/invoice-maker-pro-site/privacy.html")!)
                    }
                    Button("Terms of Use") {
                        openURL(URL(string: "https://simhado.github.io/invoice-maker-pro-site/terms.html")!)
                    }
                }

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.appVersion).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Helper
extension Bundle {
    var appVersion: String {
        let ver = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(ver) (\(build))"
    }
}
