//
//  Cards&Components.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - Cards & Components
struct QuickCreateCard: View { let newAction: () -> Void; var body: some View { ZStack { RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.1))) ; VStack(alignment: .leading, spacing: 8){ HStack{ Image(systemName:"bolt.fill").foregroundStyle(.blue); Text("Quick Create").font(.headline); Spacer(); Button(action:newAction){ HStack{ Image(systemName:"doc.badge.plus"); Text("New Invoice") }.padding(.horizontal,12).padding(.vertical,8).background(Capsule().fill(Color.black)).foregroundStyle(.white)} } ; Text("Create professional invoices in minutes").font(.subheadline).foregroundStyle(.secondary)}.padding(16)}.frame(maxWidth:.infinity) } }


struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(tint))
    }
}

struct SearchBar: View { @Binding var text: String; var body: some View { HStack{ Image(systemName:"magnifyingglass"); TextField("Search invoices…", text: $text).textInputAutocapitalization(.never).disableAutocorrection(true); if !text.isEmpty { Button{ text = "" } label: { Image(systemName:"xmark.circle.fill") } } }.padding(12).background(RoundedRectangle(cornerRadius:12).fill(Color.secondary.opacity(0.08))) } }

struct StatusChip: View { let status: Invoice.Status; var body: some View { Text(status.rawValue.capitalized).font(.caption2).padding(.horizontal,10).padding(.vertical,6).background(Capsule().stroke(Color.secondary.opacity(0.3))) }
}

struct InvoiceCard: View { let invoice: Invoice; var body: some View { ZStack { RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.15)) .background(RoundedRectangle(cornerRadius: 16).fill(.white)) ; VStack(alignment:.leading, spacing:8){ HStack{ Text(invoice.number).font(.headline); Spacer(); StatusChip(status: invoice.status) } ; Text(invoice.customer.name).font(.subheadline).foregroundStyle(.secondary) ; HStack{ Text("Due " + (invoice.dueDate.map{ Dates.display.string(from:$0) } ?? "Invalid Date" )).font(.caption).foregroundStyle(.secondary); Spacer(); Text(Money.fmt(invoice.subtotal, code: invoice.currency)).bold() } }.padding(16) } }
}
