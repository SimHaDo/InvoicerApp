//
//  PaymentMethodsEditor.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

// PaymentMethodsEditor.swift
import SwiftUI

struct PaymentMethodsEditor: View {
    @Binding var methods: [PaymentMethod]
    @State private var showAdd = false
    @State private var editMethod: PaymentMethod? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Payment Methods").font(.headline)
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            if methods.isEmpty {
                Text("No payment methods yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(methods) { m in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon(for: m.type))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.type.title).bold()
                            Text(m.type.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            Button("Edit") { editMethod = m }
                            Button("Delete", role: .destructive) {
                                if let i = methods.firstIndex(where: {$0.id == m.id}) {
                                    methods.remove(at: i)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEditPaymentMethodSheet() { new in
                methods.append(new)
            }
        }
        .sheet(item: $editMethod) { current in
            AddEditPaymentMethodSheet(existing: current) { updated in
                if let i = methods.firstIndex(where: {$0.id == current.id}) {
                    methods[i] = updated
                }
            }
        }
    }

    private func icon(for t: PaymentMethodType) -> String {
        switch t {
        case .bankIBAN: return "building.columns"
        case .bankUS:   return "banknote"
        case .paypal:   return "envelope"
        case .cardLink: return "link"
        case .crypto:   return "bitcoinsign.circle"
        case .other:    return "square.and.pencil"
        }
    }
}
