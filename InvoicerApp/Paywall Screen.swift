//
//  Paywall Screen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.


//
//  Paywall Screen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/30/25.
//

import SwiftUI
import StoreKit

struct PaywallScreen: View {
    var onClose: () -> Void = {}

    @Environment(\.colorScheme) private var scheme
    @State private var isPurchasing = false
    @State private var errorText: String?
    @State private var selected: Int = 1 // по умолчанию Monthly

    private struct Plan: Identifiable { let id: Int; let title: String; let price: String; let tag: String? }
    private let plans: [Plan] = [
        .init(id: 0, title: "Weekly",  price: "$4.99/week",  tag: nil),
        .init(id: 1, title: "Monthly", price: "$9.99/month", tag: "Best Value"),
        .init(id: 2, title: "Annual",  price: "$59.99/year", tag: nil)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {

                // MARK: Header
                VStack(spacing: 10) {
                    // Лого/иконка с ореолом
                    ZStack {
                        Circle()
                            .stroke(AngularGradient(gradient: Gradient(colors: [.blue, .purple, .blue]), center: .center), lineWidth: 2.5)
                            .frame(width: 56, height: 56)
                            .opacity(0.9)
                        Circle()
                            .fill((scheme == .light ? Color.black : Color.white).opacity(0.06))
                            .frame(width: 52, height: 52)
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(scheme == .light ? .black : .white)
                    }
                    .padding(.top, 6)

                    GradientText("Invoice Maker Pro")
                        .font(.system(size: 28, weight: .heavy))

                    Text("Unlimited invoices • 30+ templates • iCloud sync • Priority updates")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)

                    // Бейджи преимуществ
                    HStack(spacing: 8) {
                        Chip("Unlimited invoices")
                        Chip("30+ templates")
                        Chip("iCloud sync")
                    }
                    .padding(.top, 2)
                }

                // MARK: Plans
                VStack(spacing: 12) {
                    ForEach(plans) { p in
                        PlanRow(
                            title: p.title,
                            price: p.price,
                            tagText: p.tag,
                            selected: selected == p.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                selected = p.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // MARK: CTA
                Button {
                    Task {
                        isPurchasing = true
                        defer { isPurchasing = false }
                        do {
                            try await SubscriptionManager.shared.purchaseDefault()
                            onClose()
                        } catch {
                            errorText = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isPurchasing { ProgressView().tint(.white) }
                        Text(isPurchasing ? "Processing…" : "Continue with Pro")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.blue.opacity(0.22), radius: 12, y: 6)
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 16)
                .padding(.top, 2)

                if let e = errorText {
                    Text(e)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // MARK: Legal + Later
                Text("Payment will be charged to your Apple ID. Subscription auto-renews unless cancelled at least 24 hours before the end of the period. Manage or cancel in Settings → Apple ID → Subscriptions.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                Button("Maybe later") { onClose() }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
            }
            .padding(.vertical, 22)
            .padding(.bottom, 8)
            .foregroundColor(scheme == .light ? .black : .white)
        }
    }

    // MARK: Components

    private struct PlanRow: View {
        let title: String
        let price: String
        let tagText: String?
        let selected: Bool
        @Environment(\.colorScheme) private var scheme

        var body: some View {
            HStack(spacing: 12) {
                // чек-метка выбора
                ZStack {
                    Circle()
                        .fill((scheme == .light ? Color.black : Color.white).opacity(0.06))
                        .frame(width: 22, height: 22)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            .clipShape(Circle())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline.weight(.semibold))
                    Text(price).foregroundColor(.secondary)
                }
                Spacer()
                if let t = tagText {
                    Text(t)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((scheme == .light ? Color.black : Color.white).opacity(0.08))
                        )
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        selected
                        ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.primary.opacity(0.12)),
                        lineWidth: selected ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(scheme == .light ? 0.07 : 0.25),
                    radius: selected ? 12 : 8,
                    y: selected ? 8 : 5)
            .scaleEffect(selected ? 1.01 : 1.0)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selected)
        }
    }

    private struct Chip: View {
        let text: String
        init(_ text: String) { self.text = text }
        @Environment(\.colorScheme) private var scheme
        var body: some View {
            Text(text)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill((scheme == .light ? Color.black : Color.white).opacity(0.06))
                )
        }
    }

    private struct GradientText: View {
        let text: String
        init(_ text: String) { self.text = text }
        var body: some View {
            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                .mask(Text(text).font(.system(size: 28, weight: .heavy)))
        }
    }
}
