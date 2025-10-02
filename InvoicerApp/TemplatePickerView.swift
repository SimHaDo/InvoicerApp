//
//  TemplatePickerView.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/29/25.
//

import SwiftUI
import PhotosUI

struct TemplatePickerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    let onSelect: (InvoiceTemplateDescriptor) -> Void
    init(onSelect: @escaping (InvoiceTemplateDescriptor) -> Void = { _ in }) {
        self.onSelect = onSelect
    }

    @State private var photoItem: PhotosPickerItem?
    private let templates = TemplateCatalog.all

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerLogo
                ScrollView {
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        ForEach(templates) { t in
                            Button {
                                app.selectedTemplate = t
                                onSelect(t)
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    TemplateCardPreview(descriptor: t)
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08)))
                                    Text(t.name)
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(t.id == app.selectedTemplate.id ? .black : .secondary.opacity(0.15),
                                                lineWidth: t.id == app.selectedTemplate.id ? 2 : 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Invoice Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    // MARK: - Logo header
    @ViewBuilder private var headerLogo: some View {
        HStack(spacing: 12) {
            if let img = app.logoImage {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(width: 56, height: 56)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08))
                    .overlay(Text("Logo").foregroundStyle(.secondary))
                    .frame(width: 56, height: 56)
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Add / Change Logo", systemImage: "photo")
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
                Button(role: .destructive) { app.logoData = nil } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
// Новая мини-карточка превью
struct TemplateCardPreview: View {
    let descriptor: InvoiceTemplateDescriptor
    var body: some View {
        let theme = descriptor.theme
        let primary = Color(theme.primary)
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground).opacity(0.6))

            VStack(spacing: 8) {
                // top bar
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(primary.opacity(0.9))
                        .frame(width: 60, height: 14)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(primary.opacity(0.5))
                        .frame(width: 34, height: 14)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)

                // bill to / meta
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Rect(.label, w: 80, h: 10)
                        Rect(.secondaryLabel, w: 60, h: 8)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Rect(.secondaryLabel, w: 70, h: 8)
                        Rect(.secondaryLabel, w: 70, h: 8)
                        Rect(.secondaryLabel, w: 70, h: 8)
                    }
                }
                .padding(.horizontal, 10)

                // table
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(primary.opacity(0.12))
                        .frame(height: 14)
                        .padding(.horizontal, 8)
                    ForEach(0..<3) { _ in
                        HStack {
                            Rect(.label, w: 90, h: 8)
                            Spacer()
                            Rect(.label, w: 28, h: 8)
                            Rect(.label, w: 40, h: 8)
                            Rect(.label, w: 40, h: 8)
                        }
                        .padding(.horizontal, 8)
                    }
                }

                // total
                HStack {
                    Spacer()
                    Rect(.label, w: 60, h: 10)
                }
                .padding(.horizontal, 10)

                Spacer(minLength: 2)
            }
        }
    }

    private func Rect(_ uiColor: UIColor, w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(uiColor).opacity(0.85))
            .frame(width: w, height: h)
    }
}
