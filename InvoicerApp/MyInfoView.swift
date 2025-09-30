//
//  MyInfoView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

// MyInfoView.swift
// MyInfoView.swift
import SwiftUI
import PhotosUI

struct MyInfoView: View {
    @EnvironmentObject private var app: AppState

    // локальный editable слепок компании
    @State private var editingCompany: Company = .init()
    @State private var isEditingCompany = false
    @State private var showAddEditMethod = false
    @State private var editingMethod: PaymentMethod? = nil
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        List {
            // MARK: Logo
            Section("Logo") {
                HStack(spacing: 12) {
                    if let img = app.logoImage {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(width: 64, height: 64)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.06))
                            .frame(width: 64, height: 64)
                            .overlay(Text("Logo").foregroundStyle(.secondary))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(app.logoImage == nil ? "Add Logo" : "Change Logo", systemImage: "photo")
                        }
                        .onChange(of: photoItem) { new in
                            guard let new else { return }
                            Task {
                                if let data = try? await new.loadTransferable(type: Data.self) {
                                    app.logoData = data
                                }
                            }
                        }

                        if app.logoData != nil {
                            Button(role: .destructive) {
                                app.logoData = nil
                            } label: { Label("Remove Logo", systemImage: "trash") }
                        }
                    }
                }
            }

            // MARK: Company
            Section("My Company") {
                if let c = app.company, !isEditingCompany {
                    CompanySummary(company: c)
                    Button("Edit Company") { startEditingCompany(c) }
                } else {
                    CompanyEditor(company: $editingCompany)
                    HStack {
                        Button("Cancel") { isEditingCompany = false }
                        Spacer()
                        Button("Save") {
                            app.company = editingCompany
                            isEditingCompany = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(editingCompany.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            // MARK: Saved payment methods
            Section("Payment Methods") {
                if app.paymentMethods.isEmpty {
                    Text("No payment methods yet").foregroundStyle(.secondary)
                } else {
                    ForEach(app.paymentMethods) { m in
                        Button { editingMethod = m } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.type.title).bold()
                                Text(m.type.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        app.paymentMethods.remove(atOffsets: idx)
                        app.savePaymentMethods()
                    }
                }
                Button { showAddEditMethod = true } label: {
                    Label("Add Method", systemImage: "plus")
                }
            }

            // Optional notes
            Section("Additional notes") {
                TextField(
                    "Notes shown on invoice (optional)",
                    text: Binding(
                        get: { app.settings.additionalNotes ?? "" },
                        set: { newVal in
                            app.settings.additionalNotes =
                                newVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newVal
                            app.saveSettings()
                        }
                    ),
                    axis: .vertical
                )
            }
        }
        .navigationTitle("My Info")
        .onAppear {
            if let c = app.company {
                editingCompany = c
                isEditingCompany = false
            } else {
                editingCompany = Company()
                isEditingCompany = true
            }
        }
        .sheet(isPresented: $showAddEditMethod) {
            AddEditPaymentMethodSheet { new in
                app.paymentMethods.append(new)
                app.savePaymentMethods()
            }
        }
        .sheet(item: $editingMethod) { m in
            AddEditPaymentMethodSheet(existing: m) { updated in
                if let idx = app.paymentMethods.firstIndex(where: { $0.id == m.id }) {
                    app.paymentMethods[idx] = updated
                    app.savePaymentMethods()
                }
            }
        }
    }

    private func startEditingCompany(_ c: Company) {
        editingCompany = c
        isEditingCompany = true
    }
}

// MARK: - Company subviews

private struct CompanySummary: View {
    let company: Company
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(company.name).font(.headline)
            if !company.email.isEmpty { Label(company.email, systemImage: "envelope") }
            if !company.phone.isEmpty { Label(company.phone, systemImage: "phone") }
            if !company.address.oneLine.isEmpty { Label(company.address.oneLine, systemImage: "mappin.and.ellipse") }
            if let site = company.website, !site.isEmpty { Label(site, systemImage: "globe") }
        }
    }
}

private struct CompanyEditor: View {
    @Binding var company: Company
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Company name", text: $company.name)
            TextField("Email", text: $company.email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
            TextField("Phone", text: $company.phone).keyboardType(.phonePad)
            TextField("Website (optional)", text: Binding(
                get: { company.website ?? "" },
                set: { company.website = $0.isEmpty ? nil : $0 }
            ))
            Text("Address").font(.subheadline).foregroundStyle(.secondary).padding(.top, 6)
            TextField("Line 1", text: $company.address.line1)
            TextField("Line 2", text: $company.address.line2)
            HStack {
                TextField("City", text: $company.address.city)
                TextField("State", text: $company.address.state)
            }
            HStack {
                TextField("ZIP", text: $company.address.zip)
                TextField("Country", text: $company.address.country)
            }
        }
    }
}
