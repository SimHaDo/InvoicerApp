//
//  Models.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - Models
struct Address: Codable, Hashable, Identifiable { var id = UUID(); var line1 = ""; var line2 = ""; var city = ""; var state = ""; var zip = ""; var country = ""; var oneLine: String { [line1,line2,city,state,zip,country].filter{!$0.isEmpty}.joined(separator: ", ") } }

struct Company: Codable, Hashable, Identifiable { var id = UUID(); var name = ""; var email = ""; var phone = ""; var address = Address(); var website: String? = nil }

struct Customer: Codable, Hashable, Identifiable {
    var id = UUID()
    var name = ""
    var email = ""
    var phone = ""
    var address = Address()
    var organization: String? = nil     // для строки "Acme Corporation"
    var status: CustomerStatus = .active
}

enum CustomerStatus: String, Codable, CaseIterable, Identifiable {
    case active, inactive
    var id: String { rawValue }
}
struct Product: Codable, Hashable, Identifiable { var id = UUID(); var name: String; var details: String; var rate: Decimal; var category: String }

struct LineItem: Codable, Hashable, Identifiable { var id = UUID(); var description: String; var quantity: Decimal; var rate: Decimal; var total: Decimal { quantity * rate } }

struct Invoice: Codable, Hashable, Identifiable {
    enum Status: String, Codable, CaseIterable, Identifiable { case draft, sent, paid, overdue; var id: String { rawValue } }
    var id = UUID()
    var number: String
    var status: Status = .draft
    var issueDate: Date
    var dueDate: Date?
    var company: Company
    var customer: Customer
    var currency: String = Locale.current.currency?.identifier ?? "USD"
    var items: [LineItem]
    var subtotal: Decimal { items.map{$0.total}.reduce(0,+) }
    var totalPaid: Decimal = 0
    var totalDue: Decimal { max(0, subtotal - totalPaid) }
}

struct InvoiceTemplate: Hashable, Identifiable { let id = UUID(); let name: String; let summary: String; let tags: [String]; let isPremium: Bool }

enum SubscriptionState: String, Codable { case freeViewOnly, pro }
