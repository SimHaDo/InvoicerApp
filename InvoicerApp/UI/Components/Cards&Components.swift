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

struct StatusChip: View { 
    let status: Invoice.Status
    let accentColor: Color?
    @Environment(\.colorScheme) private var scheme
    
    init(status: Invoice.Status, accentColor: Color? = nil) {
        self.status = status
        self.accentColor = accentColor
    }
    
    var body: some View { 
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal,10)
            .padding(.vertical,6)
            .foregroundColor(accentColor ?? (scheme == .dark ? UI.darkText : .primary))
            .background(
                Capsule()
                    .stroke(accentColor ?? (scheme == .dark ? UI.darkStroke : Color.secondary.opacity(0.3)), lineWidth: 1.5)
            )
    }
}

struct InvoiceCard: View { 
    let invoice: Invoice
    @Environment(\.colorScheme) private var scheme
    
    private var cardColors: (background: Color, border: Color, accent: Color) {
        let isDueTomorrow = isDueDateTomorrow()
        
        if isDueTomorrow {
            return (
                background: scheme == .dark ? Color.orange.opacity(0.15) : Color.orange.opacity(0.08),
                border: Color.orange.opacity(0.4),
                accent: Color.orange
            )
        }
        
        switch invoice.status {
        case .draft:
            return (
                background: scheme == .dark ? UI.darkCardBackground : Color.gray.opacity(0.05),
                border: scheme == .dark ? UI.darkStroke : Color.gray.opacity(0.2),
                accent: Color.gray
            )
        case .paid:
            return (
                background: scheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.08),
                border: Color.green.opacity(0.4),
                accent: Color.green
            )
        case .overdue:
            return (
                background: scheme == .dark ? Color.red.opacity(0.15) : Color.red.opacity(0.08),
                border: Color.red.opacity(0.4),
                accent: Color.red
            )
        case .sent:
            return (
                background: scheme == .dark ? Color.blue.opacity(0.15) : Color.blue.opacity(0.08),
                border: Color.blue.opacity(0.4),
                accent: Color.blue
            )
        }
    }
    
    private func isDueDateTomorrow() -> Bool {
        guard let dueDate = invoice.dueDate else { return false }
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.isDate(dueDate, inSameDayAs: tomorrow)
    }
    
    private var dueDateText: String {
        if isDueDateTomorrow() {
            return "Due Date Tomorrow"
        }
        return "Due " + (invoice.dueDate.map{ Dates.display.string(from:$0) } ?? "Invalid Date")
    }
    
    var body: some View { 
        ZStack { 
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardColors.border, lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColors.background)
                )
            
            VStack(alignment:.leading, spacing:8){ 
                HStack{ 
                    Text(invoice.number)
                        .font(.headline)
                        .foregroundColor(scheme == .dark ? UI.darkText : .primary)
                    Spacer()
                    StatusChip(status: invoice.status, accentColor: cardColors.accent) 
                } 
                Text(invoice.customer.name)
                    .font(.subheadline)
                    .foregroundStyle(scheme == .dark ? UI.darkSecondaryText : .secondary) 
                HStack{ 
                    Text(dueDateText)
                        .font(.caption)
                        .foregroundStyle(cardColors.accent)
                        .fontWeight(isDueDateTomorrow() ? .semibold : .regular)
                    Spacer()
                    Text(Money.fmt(invoice.total, code: invoice.currency))
                        .bold()
                        .foregroundColor(scheme == .dark ? UI.darkText : .primary)
                } 
            }
            .padding(16) 
        } 
    }
}
