//
//  CompanySetupView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI

// MARK: - Company Setup → Template Picker → Wizard

struct CompanySetupView: View {
    @EnvironmentObject private var app: AppState
    var onContinue: () -> Void

    @State private var company = Company()

    var canSave: Bool { !company.name.trimmingCharacters(in: .whitespaces).isEmpty && !company.email.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Card
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

                    Button(action: {
                        app.company = company
                        onContinue()
                    }) {
                        Label("Continue to Invoice Creation", systemImage: "lock.fill")
                            .bold()
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
        }
    }
}

struct TemplatePickerView: View {
    @EnvironmentObject private var app: AppState
    @State private var selected: InvoiceTemplate? = Mock.templates.first

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Free Templates").font(.subheadline).foregroundStyle(.secondary)
                    ForEach(Mock.templates.filter { !$0.isPremium }) { t in
                        TemplateRow(tpl: t, selected: $selected)
                    }

                    Text("Premium Templates").font(.subheadline).foregroundStyle(.secondary).padding(.top, 8)
                    ForEach(Mock.templates.filter { $0.isPremium }) { t in
                        TemplateRow(tpl: t, selected: $selected, isLocked: true)
                    }

                    UpgradeCallout()

                    Button {
                        app.selectedTemplate = selected
                    } label: {
                        Text("Continue with \(selected?.name ?? "Template")")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black))
                            .foregroundStyle(.white)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Template")
            .navigationDestination(
                isPresented: Binding(
                    get: { app.selectedTemplate != nil },
                    set: { if !$0 { app.selectedTemplate = nil } }
                )
            ) {
                InvoiceWizardView()
            }
        }
    }
}

struct TemplateRow: View {
    let tpl: InvoiceTemplate
    @Binding var selected: InvoiceTemplate?
    var isLocked = false

    var body: some View {
        Button { selected = tpl } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected == tpl ? .black : Color.secondary.opacity(0.2), lineWidth: selected == tpl ? 2 : 1)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.05)))
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "doc.text").foregroundStyle(.secondary))
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(tpl.name).font(.headline)
                            if isLocked { Image(systemName: "crown.fill").foregroundStyle(.yellow) }
                            if selected == tpl { Image(systemName: "checkmark.circle.fill") }
                        }
                        Text(tpl.summary).font(.subheadline).foregroundStyle(.secondary)
                        WrapTags(tags: tpl.tags)
                    }
                    Spacer()
                }
                .padding(14)
            }
        }
    }
}

struct UpgradeCallout: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown").font(.title2)
            Text("Unlock Premium Templates").font(.headline)
            Text("Access 5 professional templates and advanced customization")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Upgrade Now") {}.buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
    }
}

struct WrapTags: View {
    let tags: [String]
    var body: some View {
        FlowLayout(tags) { tag in
            Text(tag)
                .font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.1)))
        }
    }
}

// Simple flow layout for chips
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    private let data: Data
    private let content: (Data.Element) -> Content
    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.content = content
    }
    var body: some View {
        GeometryReader { geo in layout(maxWidth: geo.size.width) }
            .frame(minHeight: 0)
    }
    private func layout(maxWidth: CGFloat) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0
        return ZStack(alignment: .topLeading) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .alignmentGuide(.leading) { d in
                        if x + d.width > maxWidth {
                            x = 0; y -= d.height
                        }
                        let res = x; x -= d.width
                        return res
                    }
                    .alignmentGuide(.top) { _ in y }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
