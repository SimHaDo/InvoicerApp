//
//  CompanySetupView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// Company Setup → возвращает управление наверх через onContinue
struct CompanySetupView: View {
    @EnvironmentObject private var app: AppState
    var onContinue: () -> Void

    @State private var company = Company()

    private var canSave: Bool {
        !company.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !company.email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Company Information").font(.headline)
                        TextField("Your Company Name", text: $company.name).fieldStyle()
                        HStack {
                            TextField("company@example.com", text: $company.email).keyboardType(.emailAddress).fieldStyle()
                            TextField("+1 (555) 123-4567", text: $company.phone).keyboardType(.phonePad).fieldStyle()
                        }
                        TextField("123 Business Street, City, State 12345", text: $company.address.line1).fieldStyle()
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.12)))

                    Button {
                        app.company = company
                        onContinue()
                    } label: {
                        Text("Continue to Invoice Creation").bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black))
                            .foregroundStyle(.white)
                    }
                    .disabled(!canSave)
                }
                .padding()
            }
            .navigationTitle("Company Setup")
            .onAppear {
                // если уже была сохранена — подставим для редактирования
                company = app.company ?? Company()
            }
        }
    }
}

