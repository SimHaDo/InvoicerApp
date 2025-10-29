//
//  AnalyticsScreen.swift
//  InvoicerApp
//
//  Created by Danyil Skrypnichenko on 9/27/25.
//

import SwiftUI
import Charts

// MARK: - FloatingElement

private struct FloatingElement: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}

// MARK: - Analytics Data Models

struct RevenueData: Identifiable {
    let id = UUID()
    let month: String
    let revenue: Double
    let invoices: Int
}

struct CustomerSegment: Identifiable {
    let id = UUID()
    let name: String
    let revenue: Double
    let invoices: Int
    let percentage: Double
}

struct PaymentTrend: Identifiable {
    let id = UUID()
    let period: String
    let paid: Double
    let pending: Double
    let overdue: Double
}

// MARK: - Extended Analytics Models

struct AnalyticsMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let category: MetricCategory
    let isPremium: Bool
    let trend: TrendDirection?
    let trendValue: Double?
    let description: String
    let detailedExplanation: String
    let chartData: [ChartDataPoint]
    let heatmapData: [HeatmapDataPoint]
}

enum MetricCategory: String, CaseIterable {
    case revenue = "Revenue"
    case performance = "Performance"
    case customers = "Customers"
    case efficiency = "Efficiency"
    case growth = "Growth"
    case payment = "Payment"
}

enum TrendDirection {
    case up, down, stable
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    let date: Date?
}

struct HeatmapDataPoint: Identifiable {
    let id = UUID()
    let x: Int
    let y: Int
    let value: Double
    let color: Color
    let label: String?
}

struct MetricDetailView: Identifiable {
    let id = UUID()
    let metric: AnalyticsMetric
    let chartType: ChartType
    let additionalData: [String: Any]
}

enum ChartType {
    case line, bar, pie, radar, heatmap, donut
}

// MARK: - Fullscreen Cover Models

struct FullscreenMetricCover: Identifiable {
    let id = UUID()
    let metric: AnalyticsMetric
    let isPresented: Bool
    let animationOffset: CGFloat
    let backgroundBlur: Double
}

// MARK: - ViewModel

final class AnalyticsVM: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var selectedTimeframe: TimeFrame = .month
    @Published var selectedMetric: MetricType = .revenue
    @Published var selectedMetricForDetail: AnalyticsMetric?
    @Published var showFullscreenCover = false
    @Published var animationProgress: Double = 0
    @Published var heatmapAnimationProgress: Double = 0
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    enum MetricType: String, CaseIterable {
        case revenue = "Revenue"
        case invoices = "Invoices"
        case customers = "Customers"
        case payments = "Payments"
    }
    
    // MARK: - Extended Analytics Metrics
    
    func getAllMetrics(for invoices: [Invoice], currency: String) -> [AnalyticsMetric] {
        return [
            // Revenue Metrics
            createRevenueMetric(invoices: invoices, currency: currency),
            createRevenueGrowthMetric(invoices: invoices, currency: currency),
            createAverageInvoiceValueMetric(invoices: invoices, currency: currency),
            
            // Performance Metrics
            createPaymentRateMetric(invoices: invoices),
            createInvoiceVelocityMetric(invoices: invoices),
            createCollectionEfficiencyMetric(invoices: invoices, currency: currency),
            
            // Customer Metrics
            createCustomerLTVMetric(invoices: invoices, currency: currency),
            createCustomerRetentionMetric(invoices: invoices),
            createTopCustomerContributionMetric(invoices: invoices, currency: currency),
            
            // Efficiency Metrics
            createInvoiceProcessingTimeMetric(invoices: invoices),
            createPaymentSpeedMetric(invoices: invoices),
            createOverdueRateMetric(invoices: invoices),
            
            // Growth Metrics
            createMonthlyGrowthRateMetric(invoices: invoices, currency: currency),
            createCustomerAcquisitionMetric(invoices: invoices),
            createRevenuePerCustomerMetric(invoices: invoices, currency: currency),
            
            // Payment Metrics
            createPaymentMethodDistributionMetric(invoices: invoices),
            createPaymentTrendMetric(invoices: invoices, currency: currency),
            createOutstandingAmountMetric(invoices: invoices, currency: currency)
        ]
    }
    
    func createRevenueMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let totalRevenue = totalRevenue(invoices)
        let paidInvoices = paidInvoices(invoices)
        let _ = totalInvoices(invoices)
        
        let chartData = monthlyRevenueData(invoices).map { data in
            ChartDataPoint(
                label: data.month,
                value: data.revenue,
                color: .blue,
                date: nil
            )
        }
        
        let heatmapData = createRevenueHeatmapData(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Total Revenue",
            value: Money.fmt(totalRevenue, code: currency),
            subtitle: "From \(paidInvoices) paid invoices",
            icon: "dollarsign.circle.fill",
            color: .green,
            category: .revenue,
            isPremium: false,
            trend: .up,
            trendValue: revenueGrowth(invoices),
            description: "Total revenue from all paid invoices",
            detailedExplanation: "This metric shows your total revenue generated from paid invoices. It's calculated by summing up the subtotal amounts of all invoices with 'paid' status. This is your primary income indicator and helps track business performance over time.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createRevenueGrowthMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let growth = revenueGrowth(invoices)
        
        let chartData = createGrowthChartData(invoices: invoices)
        let heatmapData = createGrowthHeatmapData(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Revenue Growth",
            value: "\(growth >= 0 ? "+" : "")\(String(format: "%.1f", growth))%",
            subtitle: "vs previous month",
            icon: "chart.line.uptrend.xyaxis",
            color: growth >= 0 ? .green : .red,
            category: .growth,
            isPremium: true,
            trend: growth >= 0 ? .up : .down,
            trendValue: abs(growth),
            description: "Month-over-month revenue growth percentage",
            detailedExplanation: "Revenue growth shows how much your income has increased or decreased compared to the previous month. Positive growth indicates business expansion, while negative growth may signal challenges. This metric is crucial for understanding business momentum and making strategic decisions.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createAverageInvoiceValueMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let avgValue = avgInvoiceValue(invoices)
        let chartData = createAverageValueChartData(invoices: invoices, currency: currency)
        let heatmapData = createValueDistributionHeatmap(invoices: invoices, currency: currency)
        
        return AnalyticsMetric(
            title: "Average Invoice Value",
            value: Money.fmt(avgValue, code: currency),
            subtitle: "Per invoice",
            icon: "chart.bar.fill",
            color: .orange,
            category: .revenue,
            isPremium: false,
            trend: nil,
            trendValue: nil,
            description: "Average value per invoice",
            detailedExplanation: "This metric shows the average monetary value of your invoices. It helps you understand your pricing strategy effectiveness and identify opportunities to increase invoice values. Higher average values often indicate better client relationships and service quality.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createPaymentRateMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let rate = paymentRate(invoices)
        let chartData = createPaymentRateChartData(invoices: invoices)
        let heatmapData = createPaymentStatusHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Payment Rate",
            value: "\(Int(rate * 100))%",
            subtitle: "Success rate",
            icon: "percent",
            color: .green,
            category: .performance,
            isPremium: true,
            trend: rate > 0.8 ? .up : (rate < 0.6 ? .down : .stable),
            trendValue: rate * 100,
            description: "Percentage of invoices that get paid",
            detailedExplanation: "Payment rate indicates how successful you are at collecting payments. A high rate (80%+) suggests good client relationships and effective follow-up processes. Low rates may indicate pricing issues, client satisfaction problems, or inadequate collection procedures.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createInvoiceVelocityMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let velocity = invoiceVelocity(invoices)
        let chartData = createVelocityChartData(invoices: invoices)
        let heatmapData = createVelocityHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Invoice Velocity",
            value: String(format: "%.1f", velocity),
            subtitle: "per month",
            icon: "speedometer",
            color: .blue,
            category: .efficiency,
            isPremium: true,
            trend: velocity > 10 ? .up : (velocity < 5 ? .down : .stable),
            trendValue: velocity,
            description: "Number of invoices created per month",
            detailedExplanation: "Invoice velocity measures how quickly you generate new invoices. Higher velocity indicates active business operations and consistent client work. This metric helps track business activity levels and can predict revenue trends.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createCollectionEfficiencyMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let overdueAmount = invoices.filter { $0.status == .overdue }.map(\.total).reduce(0, +)
        let totalAmount = invoices.map(\.total).reduce(0, +)
        let efficiency = totalAmount > 0 ? 1 - (Double(truncating: NSDecimalNumber(decimal: overdueAmount)) / Double(truncating: NSDecimalNumber(decimal: totalAmount))) : 1.0
        
        let chartData = createCollectionEfficiencyChartData(invoices: invoices, currency: currency)
        let heatmapData = createCollectionHeatmap(invoices: invoices, currency: currency)
        
        return AnalyticsMetric(
            title: "Collection Efficiency",
            value: "\(Int(efficiency * 100))%",
            subtitle: "Collection success",
            icon: "checkmark.circle.fill",
            color: efficiency > 0.9 ? .green : (efficiency > 0.7 ? .orange : .red),
            category: .efficiency,
            isPremium: true,
            trend: efficiency > 0.9 ? .up : (efficiency < 0.7 ? .down : .stable),
            trendValue: efficiency * 100,
            description: "Efficiency of payment collection",
            detailedExplanation: "Collection efficiency measures how well you collect payments on time. It's calculated as the percentage of total invoice value that's not overdue. High efficiency (90%+) indicates strong cash flow management and client relationships.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createCustomerLTVMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let ltv = customerLifetimeValue(invoices)
        let chartData = createLTVChartData(invoices: invoices, currency: currency)
        let heatmapData = createCustomerValueHeatmap(invoices: invoices, currency: currency)
        
        return AnalyticsMetric(
            title: "Customer LTV",
            value: Money.fmt(ltv, code: currency),
            subtitle: "Lifetime value",
            icon: "person.crop.circle.fill",
            color: .purple,
            category: .customers,
            isPremium: true,
            trend: nil,
            trendValue: nil,
            description: "Average customer lifetime value",
            detailedExplanation: "Customer Lifetime Value (LTV) represents the average revenue generated per customer over their entire relationship with your business. Higher LTV indicates strong customer relationships and successful upselling strategies.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createCustomerRetentionMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let retention = calculateCustomerRetention(invoices: invoices)
        let chartData = createRetentionChartData(invoices: invoices)
        let heatmapData = createRetentionHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Customer Retention",
            value: "\(Int(retention * 100))%",
            subtitle: "Repeat customers",
            icon: "person.2.fill",
            color: retention > 0.7 ? .green : (retention > 0.5 ? .orange : .red),
            category: .customers,
            isPremium: true,
            trend: retention > 0.7 ? .up : (retention < 0.5 ? .down : .stable),
            trendValue: retention * 100,
            description: "Percentage of repeat customers",
            detailedExplanation: "Customer retention measures how many of your customers return for additional services. High retention (70%+) indicates satisfied customers and strong business relationships. This metric is crucial for sustainable growth.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createTopCustomerContributionMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let topCustomers = topCustomers(invoices)
        let topCustomerRevenue = topCustomers.first?.revenue ?? 0
        let totalRevenue = invoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
        let contribution = totalRevenue > 0 ? (topCustomerRevenue / Double(truncating: NSDecimalNumber(decimal: totalRevenue))) * 100 : 0
        
        let chartData = createTopCustomerChartData(customers: topCustomers, currency: currency)
        let heatmapData = createCustomerContributionHeatmap(customers: topCustomers)
        
        return AnalyticsMetric(
            title: "Top Customer Share",
            value: "\(String(format: "%.1f", contribution))%",
            subtitle: "Revenue share",
            icon: "star.fill",
            color: .yellow,
            category: .customers,
            isPremium: true,
            trend: nil,
            trendValue: contribution,
            description: "Revenue share of top customer",
            detailedExplanation: "This metric shows what percentage of your total revenue comes from your top customer. While high values indicate strong relationships, excessive concentration (50%+) may pose business risks if that customer leaves.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createInvoiceProcessingTimeMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let avgProcessingTime = calculateAverageProcessingTime(invoices: invoices)
        let chartData = createProcessingTimeChartData(invoices: invoices)
        let heatmapData = createProcessingTimeHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Processing Time",
            value: "\(Int(avgProcessingTime)) days",
            subtitle: "Average",
            icon: "clock.fill",
            color: avgProcessingTime < 7 ? .green : (avgProcessingTime < 14 ? .orange : .red),
            category: .efficiency,
            isPremium: true,
            trend: avgProcessingTime < 7 ? .up : (avgProcessingTime > 14 ? .down : .stable),
            trendValue: avgProcessingTime,
            description: "Average time to process invoices",
            detailedExplanation: "Processing time measures how quickly you create and send invoices after completing work. Shorter processing times improve cash flow and client satisfaction. Best practices suggest processing within 1-3 days.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createPaymentSpeedMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let avgPaymentSpeed = calculateAveragePaymentSpeed(invoices: invoices)
        let chartData = createPaymentSpeedChartData(invoices: invoices)
        let heatmapData = createPaymentSpeedHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Payment Speed",
            value: "\(Int(avgPaymentSpeed)) days",
            subtitle: "Average",
            icon: "timer",
            color: avgPaymentSpeed < 14 ? .green : (avgPaymentSpeed < 30 ? .orange : .red),
            category: .payment,
            isPremium: true,
            trend: avgPaymentSpeed < 14 ? .up : (avgPaymentSpeed > 30 ? .down : .stable),
            trendValue: avgPaymentSpeed,
            description: "Average time to receive payments",
            detailedExplanation: "Payment speed measures how quickly clients pay their invoices. Faster payments improve cash flow. Industry standards vary, but 14-30 days is typical for most businesses. Faster payments indicate strong client relationships.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createOverdueRateMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let overdueCount = overdueInvoices(invoices)
        let totalCount = totalInvoices(invoices)
        let overdueRate = totalCount > 0 ? Double(overdueCount) / Double(totalCount) : 0
        
        let chartData = createOverdueRateChartData(invoices: invoices)
        let heatmapData = createOverdueHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Overdue Rate",
            value: "\(Int(overdueRate * 100))%",
            subtitle: "Overdue invoices",
            icon: "exclamationmark.triangle.fill",
            color: overdueRate < 0.1 ? .green : (overdueRate < 0.2 ? .orange : .red),
            category: .payment,
            isPremium: true,
            trend: overdueRate < 0.1 ? .up : (overdueRate > 0.2 ? .down : .stable),
            trendValue: overdueRate * 100,
            description: "Percentage of overdue invoices",
            detailedExplanation: "Overdue rate shows what percentage of your invoices are past due. Lower rates (under 10%) indicate effective collection processes and good client relationships. High rates may require improved follow-up procedures.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createMonthlyGrowthRateMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let growth = revenueGrowth(invoices)
        let chartData = createMonthlyGrowthChartData(invoices: invoices, currency: currency)
        let heatmapData = createGrowthTrendHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "Monthly Growth",
            value: "\(growth >= 0 ? "+" : "")\(String(format: "%.1f", growth))%",
            subtitle: "vs last month",
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            color: growth >= 0 ? .green : .red,
            category: .growth,
            isPremium: true,
            trend: growth >= 0 ? .up : .down,
            trendValue: abs(growth),
            description: "Month-over-month growth rate",
            detailedExplanation: "Monthly growth rate shows the percentage change in revenue compared to the previous month. Consistent positive growth indicates healthy business expansion, while negative growth may signal challenges requiring attention.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createCustomerAcquisitionMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let newCustomers = calculateNewCustomers(invoices: invoices)
        let chartData = createAcquisitionChartData(invoices: invoices)
        let heatmapData = createAcquisitionHeatmap(invoices: invoices)
        
        return AnalyticsMetric(
            title: "New Customers",
            value: "\(newCustomers)",
            subtitle: "This month",
            icon: "person.badge.plus.fill",
            color: .blue,
            category: .growth,
            isPremium: true,
            trend: newCustomers > 0 ? .up : .stable,
            trendValue: Double(newCustomers),
            description: "Number of new customers acquired",
            detailedExplanation: "This metric tracks how many new customers you've acquired in the current month. Consistent new customer acquisition is essential for business growth and helps offset any customer churn.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createRevenuePerCustomerMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let totalRevenue = totalRevenue(invoices)
        let uniqueCustomers = uniqueClients(invoices)
        let revenuePerCustomer = uniqueCustomers > 0 ? totalRevenue / Decimal(uniqueCustomers) : 0
        
        let chartData = createRevenuePerCustomerChartData(invoices: invoices, currency: currency)
        let heatmapData = createRevenuePerCustomerHeatmap(invoices: invoices, currency: currency)
        
        return AnalyticsMetric(
            title: "Revenue per Customer",
            value: Money.fmt(revenuePerCustomer, code: currency),
            subtitle: "Average",
            icon: "person.crop.circle.badge.dollarsign",
            color: .purple,
            category: .customers,
            isPremium: true,
            trend: nil,
            trendValue: nil,
            description: "Average revenue per customer",
            detailedExplanation: "Revenue per customer shows the average monetary value each customer brings to your business. Higher values indicate successful upselling, premium pricing, or high-value service offerings.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createPaymentMethodDistributionMetric(invoices: [Invoice]) -> AnalyticsMetric {
        let paymentMethods = calculatePaymentMethodDistribution(invoices: invoices)
        let chartData = createPaymentMethodChartData(paymentMethods: paymentMethods)
        let heatmapData = createPaymentMethodHeatmap(paymentMethods: paymentMethods)
        
        return AnalyticsMetric(
            title: "Payment Methods",
            value: "\(paymentMethods.count) types",
            subtitle: "Available",
            icon: "creditcard.fill",
            color: .blue,
            category: .payment,
            isPremium: true,
            trend: nil,
            trendValue: nil,
            description: "Distribution of payment methods",
            detailedExplanation: "This metric shows how your customers prefer to pay. Understanding payment preferences helps optimize your payment collection process and improve customer experience.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createPaymentTrendMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let trends = paymentTrends(invoices)
        let chartData = createPaymentTrendChartData(trends: trends, currency: currency)
        let heatmapData = createPaymentTrendHeatmap(trends: trends)
        
        return AnalyticsMetric(
            title: "Payment Trends",
            value: "\(trends.count) periods",
            subtitle: "Tracked",
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            color: .green,
            category: .payment,
            isPremium: true,
            trend: nil,
            trendValue: nil,
            description: "Payment trends over time",
            detailedExplanation: "Payment trends show how your payment collection performance changes over time. This helps identify seasonal patterns, collection challenges, and improvement opportunities.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    func createOutstandingAmountMetric(invoices: [Invoice], currency: String) -> AnalyticsMetric {
        let outstanding = invoices.filter { $0.status != .paid }.map(\.total).reduce(0, +)
        let chartData = createOutstandingChartData(invoices: invoices, currency: currency)
        let heatmapData = createOutstandingHeatmap(invoices: invoices, currency: currency)
        
        return AnalyticsMetric(
            title: "Outstanding Amount",
            value: Money.fmt(outstanding, code: currency),
            subtitle: "Unpaid invoices",
            icon: "exclamationmark.circle.fill",
            color: .orange,
            category: .payment,
            isPremium: true,
            trend: nil,
            trendValue: nil,
            description: "Total amount of unpaid invoices",
            detailedExplanation: "Outstanding amount represents the total value of unpaid invoices. This metric is crucial for cash flow management and helps prioritize collection efforts. Lower outstanding amounts indicate better cash flow.",
            chartData: chartData,
            heatmapData: heatmapData
        )
    }
    
    // MARK: - Basic Metrics (Free)
    
    func totalInvoices(_ invoices: [Invoice]) -> Int { 
        invoices.count 
    }

    func totalRevenue(_ invoices: [Invoice]) -> Decimal {
        invoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
    }

    func paidInvoices(_ invoices: [Invoice]) -> Int {
        invoices.filter { $0.status == .paid }.count
    }
    
    func pendingInvoices(_ invoices: [Invoice]) -> Int {
        invoices.filter { $0.status == .draft }.count
    }
    
    func overdueInvoices(_ invoices: [Invoice]) -> Int {
        invoices.filter { $0.status == .overdue }.count
    }
    
    func uniqueClients(_ invoices: [Invoice]) -> Int {
        Set(invoices.map { $0.customer.id }).count
    }
    
    func avgInvoiceValue(_ invoices: [Invoice]) -> Decimal {
        guard !invoices.isEmpty else { return 0 }
        let total = invoices.map(\.subtotal).reduce(0, +)
        return total / Decimal(invoices.count)
    }
    
    // MARK: - Advanced Metrics (Premium)

    func paymentRate(_ invoices: [Invoice]) -> Double {
        guard !invoices.isEmpty else { return 0 }
        let paidCount = invoices.filter { $0.status == .paid }.count
        return Double(paidCount) / Double(invoices.count)
    }

    func revenueGrowth(_ invoices: [Invoice]) -> Double {
        let currentMonth = Calendar.current.date(byAdding: .month, value: 0, to: Date())!
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        
        let currentRevenue = invoices.filter { 
            $0.issueDate >= currentMonth && $0.status == .paid 
        }.map(\.subtotal).reduce(0, +)
        
        let previousRevenue = invoices.filter { 
            $0.issueDate >= previousMonth && $0.issueDate < currentMonth && $0.status == .paid 
        }.map(\.subtotal).reduce(0, +)
        
        guard previousRevenue > 0 else { return 0 }
        return Double(truncating: NSDecimalNumber(decimal: currentRevenue - previousRevenue)) / Double(truncating: NSDecimalNumber(decimal: previousRevenue)) * 100
    }
    
    func topCustomers(_ invoices: [Invoice]) -> [CustomerSegment] {
        let customerRevenue = Dictionary(grouping: invoices.filter { $0.status == .paid }) { $0.customer.id }
            .mapValues { invoices in
                (invoices.map(\.subtotal).reduce(0, +), invoices.count)
            }
        
        let totalRevenue = customerRevenue.values.map(\.0).reduce(0, +)
        
        return customerRevenue.compactMap { (customerId, data) in
            guard let customer = invoices.first(where: { $0.customer.id == customerId })?.customer else { return nil }
            let revenueDouble = Double(truncating: NSDecimalNumber(decimal: data.0))
            let totalRevenueDouble = Double(truncating: NSDecimalNumber(decimal: totalRevenue))
            return CustomerSegment(
                name: customer.name,
                revenue: revenueDouble,
                invoices: data.1,
                percentage: totalRevenue > 0 ? revenueDouble / totalRevenueDouble * 100 : 0
            )
        }.sorted { $0.revenue > $1.revenue }.prefix(5).map { $0 }
    }
    
    func monthlyRevenueData(_ invoices: [Invoice]) -> [RevenueData] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd && $0.status == .paid 
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            let revenue = monthInvoices.map(\.subtotal).reduce(0, +)
            return RevenueData(
                month: formatter.string(from: monthStart),
                revenue: Double(truncating: NSDecimalNumber(decimal: revenue)),
                invoices: monthInvoices.count
            )
        }.reversed()
    }
    
    func paymentTrends(_ invoices: [Invoice]) -> [PaymentTrend] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<4).compactMap { weeksBack in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: now),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return nil }
            
            let weekInvoices = invoices.filter { 
                $0.issueDate >= weekStart && $0.issueDate < weekEnd 
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            
            let paidRevenue = weekInvoices.filter { $0.status == .paid }.map(\.subtotal).reduce(0, +)
            let pendingRevenue = weekInvoices.filter { $0.status == .draft }.map(\.subtotal).reduce(0, +)
            let overdueRevenue = weekInvoices.filter { $0.status == .overdue }.map(\.subtotal).reduce(0, +)
            
            return PaymentTrend(
                period: formatter.string(from: weekStart),
                paid: Double(truncating: NSDecimalNumber(decimal: paidRevenue)),
                pending: Double(truncating: NSDecimalNumber(decimal: pendingRevenue)),
                overdue: Double(truncating: NSDecimalNumber(decimal: overdueRevenue))
            )
        }.reversed()
    }
    
    func invoiceVelocity(_ invoices: [Invoice]) -> Double {
        guard invoices.count > 1 else { return 0 }
        let sortedInvoices = invoices.sorted { $0.issueDate < $1.issueDate }
        let firstDate = sortedInvoices.first!.issueDate
        let lastDate = sortedInvoices.last!.issueDate
        let daysBetween = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
        return Double(invoices.count) / Double(daysBetween) * 30 // invoices per month
    }
    
    func customerLifetimeValue(_ invoices: [Invoice]) -> Decimal {
        let customerRevenue = Dictionary(grouping: invoices.filter { $0.status == .paid }) { $0.customer.id }
            .mapValues { invoices in invoices.map(\.subtotal).reduce(0, +) }
        
        guard !customerRevenue.isEmpty else { return 0 }
        let totalRevenue = customerRevenue.values.reduce(0, +)
        return totalRevenue / Decimal(customerRevenue.count)
    }
    
    // MARK: - Helper Functions for Chart Data
    
    func createRevenueHeatmapData(invoices: [Invoice]) -> [HeatmapDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var heatmapData: [HeatmapDataPoint] = []
        
        // Create 7x4 heatmap for last 4 weeks
        for week in 0..<4 {
            for day in 0..<7 {
                let dayOffset = week * 7 + day
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                
                let dayInvoices = invoices.filter { 
                    calendar.isDate($0.issueDate, inSameDayAs: date) && $0.status == .paid 
                }
                let dayRevenue = dayInvoices.map(\.subtotal).reduce(0, +)
                let maxRevenue = invoices.map(\.subtotal).max() ?? 1
                let intensity = Double(truncating: NSDecimalNumber(decimal: dayRevenue)) / Double(truncating: NSDecimalNumber(decimal: maxRevenue))
                
                heatmapData.append(HeatmapDataPoint(
                    x: day,
                    y: week,
                    value: intensity,
                    color: Color.green.opacity(intensity),
                    label: "\(Int(truncating: NSDecimalNumber(decimal: dayRevenue)))"
                ))
            }
        }
        
        return heatmapData
    }
    
    func createGrowthChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Если нет данных, создаем пустые полосы
        if invoices.isEmpty {
            return (0..<6).map { monthsBack in
                let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now) ?? now
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return ChartDataPoint(
                    label: formatter.string(from: monthStart),
                    value: 0,
                    color: .gray.opacity(0.3),
                    date: monthStart
                )
            }
        }
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd && $0.status == .paid 
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            let revenue = monthInvoices.map(\.subtotal).reduce(0, +)
            return ChartDataPoint(
                label: formatter.string(from: monthStart),
                value: Double(truncating: NSDecimalNumber(decimal: revenue)),
                color: .blue,
                date: monthStart
            )
        }.reversed()
    }
    
    func createGrowthHeatmapData(invoices: [Invoice]) -> [HeatmapDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var heatmapData: [HeatmapDataPoint] = []
        
        // Create 12x4 heatmap for last 12 months
        for month in 0..<12 {
            for week in 0..<4 {
                guard let monthStart = calendar.date(byAdding: .month, value: -month, to: now),
                      let weekStart = calendar.date(byAdding: .weekOfYear, value: -week, to: monthStart) else { continue }
                
                let weekInvoices = invoices.filter { 
                    $0.issueDate >= weekStart && $0.issueDate < calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
                    && $0.status == .paid 
                }
                let weekRevenue = weekInvoices.map(\.subtotal).reduce(0, +)
                let maxRevenue = invoices.map(\.subtotal).max() ?? 1
                let intensity = Double(truncating: NSDecimalNumber(decimal: weekRevenue)) / Double(truncating: NSDecimalNumber(decimal: maxRevenue))
                
                heatmapData.append(HeatmapDataPoint(
                    x: week,
                    y: month,
                    value: intensity,
                    color: Color.blue.opacity(intensity),
                    label: "\(Int(truncating: NSDecimalNumber(decimal: weekRevenue)))"
                ))
            }
        }
        
        return heatmapData
    }
    
    func createAverageValueChartData(invoices: [Invoice], currency: String) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd 
            }
            
            guard !monthInvoices.isEmpty else { return nil }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            let avgValue = monthInvoices.map(\.subtotal).reduce(0, +) / Decimal(monthInvoices.count)
            return ChartDataPoint(
                label: formatter.string(from: monthStart),
                value: Double(truncating: NSDecimalNumber(decimal: avgValue)),
                color: .orange,
                date: monthStart
            )
        }.reversed()
    }
    
    func createValueDistributionHeatmap(invoices: [Invoice], currency: String) -> [HeatmapDataPoint] {
        let valueRanges = [
            (0, 100, "0-100"),
            (100, 500, "100-500"),
            (500, 1000, "500-1K"),
            (1000, 5000, "1K-5K"),
            (5000, 10000, "5K-10K"),
            (10000, Double.infinity, "10K+")
        ]
        
        var heatmapData: [HeatmapDataPoint] = []
        
        for (index, range) in valueRanges.enumerated() {
            let invoicesInRange = invoices.filter { invoice in
                let value = Double(truncating: NSDecimalNumber(decimal: invoice.subtotal))
                return value >= Double(range.0) && value < Double(range.1)
            }
            
            let count = invoicesInRange.count
            let totalInvoices = invoices.count
            let intensity = totalInvoices > 0 ? Double(count) / Double(totalInvoices) : 0
            
            heatmapData.append(HeatmapDataPoint(
                x: index,
                y: 0,
                value: intensity,
                color: Color.orange.opacity(intensity),
                label: "\(count)"
            ))
        }
        
        return heatmapData
    }
    
    func createPaymentRateChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Если нет данных, создаем пустые полосы
        if invoices.isEmpty {
            return (0..<6).map { monthsBack in
                let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now) ?? now
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return ChartDataPoint(
                    label: formatter.string(from: monthStart),
                    value: 0,
                    color: .gray.opacity(0.3),
                    date: monthStart
                )
            }
        }
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd 
            }
            
            guard !monthInvoices.isEmpty else { return nil }
            
            let paidCount = monthInvoices.filter { $0.status == .paid }.count
            let rate = Double(paidCount) / Double(monthInvoices.count)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            return ChartDataPoint(
                label: formatter.string(from: monthStart),
                value: rate * 100,
                color: .green,
                date: monthStart
            )
        }.reversed()
    }
    
    func createPaymentStatusHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        let statuses: [(Invoice.Status, Color)] = [
            (.paid, .green),
            (.draft, .blue),
            (.sent, .orange),
            (.overdue, .red)
        ]
        
        var heatmapData: [HeatmapDataPoint] = []
        
        for (index, status) in statuses.enumerated() {
            let count = invoices.filter { $0.status == status.0 }.count
            let totalInvoices = invoices.count
            let intensity = totalInvoices > 0 ? Double(count) / Double(totalInvoices) : 0
            
            heatmapData.append(HeatmapDataPoint(
                x: index,
                y: 0,
                value: intensity,
                color: status.1.opacity(intensity),
                label: "\(count)"
            ))
        }
        
        return heatmapData
    }
    
    func createVelocityChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Если нет данных, создаем пустые полосы
        if invoices.isEmpty {
            return (0..<6).map { monthsBack in
                let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now) ?? now
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return ChartDataPoint(
                    label: formatter.string(from: monthStart),
                    value: 0,
                    color: .gray.opacity(0.3),
                    date: monthStart
                )
            }
        }
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd 
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            return ChartDataPoint(
                label: formatter.string(from: monthStart),
                value: Double(monthInvoices.count),
                color: .blue,
                date: monthStart
            )
        }.reversed()
    }
    
    func createVelocityHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var heatmapData: [HeatmapDataPoint] = []
        
        // Create 7x4 heatmap for last 4 weeks
        for week in 0..<4 {
            for day in 0..<7 {
                let dayOffset = week * 7 + day
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                
                let dayInvoices = invoices.filter { 
                    calendar.isDate($0.issueDate, inSameDayAs: date)
                }
                let count = dayInvoices.count
                let maxCount = invoices.count > 0 ? invoices.count / 30 : 1 // Approximate max per day
                let intensity = Double(count) / Double(maxCount)
                
                heatmapData.append(HeatmapDataPoint(
                    x: day,
                    y: week,
                    value: intensity,
                    color: Color.blue.opacity(intensity),
                    label: "\(count)"
                ))
            }
        }
        
        return heatmapData
    }
    
    // MARK: - Additional Helper Functions
    
    func calculateCustomerRetention(invoices: [Invoice]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.dateInterval(of: .month, for: now)!
        let previousMonth = calendar.dateInterval(of: .month, for: calendar.date(byAdding: .month, value: -1, to: now)!)!
        
        let currentCustomers = Set(invoices.filter { 
            currentMonth.contains($0.issueDate) 
        }.map { $0.customer.id })
        
        let previousCustomers = Set(invoices.filter { 
            previousMonth.contains($0.issueDate) 
        }.map { $0.customer.id })
        
        let returningCustomers = currentCustomers.intersection(previousCustomers).count
        let totalPreviousCustomers = previousCustomers.count
        
        return totalPreviousCustomers > 0 ? Double(returningCustomers) / Double(totalPreviousCustomers) : 0
    }
    
    func calculateNewCustomers(invoices: [Invoice]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.dateInterval(of: .month, for: now)!
        let previousMonths = calendar.dateInterval(of: .month, for: calendar.date(byAdding: .month, value: -1, to: now)!)!
        
        let currentCustomers = Set(invoices.filter { 
            currentMonth.contains($0.issueDate) 
        }.map { $0.customer.id })
        
        let previousCustomers = Set(invoices.filter { 
            previousMonths.contains($0.issueDate) 
        }.map { $0.customer.id })
        
        return currentCustomers.subtracting(previousCustomers).count
    }
    
    func calculateAverageProcessingTime(invoices: [Invoice]) -> Double {
        // Simplified calculation - in real app, you'd track when work was completed
        let calendar = Calendar.current
        let now = Date()
        
        let recentInvoices = invoices.filter { 
            $0.issueDate >= calendar.date(byAdding: .month, value: -3, to: now)!
        }
        
        guard !recentInvoices.isEmpty else { return 0 }
        
        let totalDays = recentInvoices.compactMap { invoice in
            calendar.dateComponents([.day], from: invoice.issueDate, to: now).day
        }.reduce(0, +)
        
        return Double(totalDays) / Double(recentInvoices.count)
    }
    
    func calculateAveragePaymentSpeed(invoices: [Invoice]) -> Double {
        let paidInvoices = invoices.filter { $0.status == .paid }
        guard !paidInvoices.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let totalDays = paidInvoices.compactMap { invoice in
            calendar.dateComponents([.day], from: invoice.issueDate, to: Date()).day
        }.reduce(0, +)
        
        return Double(totalDays) / Double(paidInvoices.count)
    }
    
    func calculatePaymentMethodDistribution(invoices: [Invoice]) -> [(String, Int)] {
        let allMethods = invoices.flatMap { $0.paymentMethods }
        let methodCounts = Dictionary(grouping: allMethods) { $0.type.title }
            .mapValues { $0.count }
        
        return methodCounts.sorted { $0.value > $1.value }
    }
    
    // MARK: - Additional Chart Data Functions
    
    func createCollectionEfficiencyChartData(invoices: [Invoice], currency: String) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<6).compactMap { monthsBack in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: now),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
            
            let monthInvoices = invoices.filter { 
                $0.issueDate >= monthStart && $0.issueDate < monthEnd 
            }
            
            guard !monthInvoices.isEmpty else { return nil }
            
            let overdueAmount = monthInvoices.filter { $0.status == .overdue }.map(\.total).reduce(0, +)
            let totalAmount = monthInvoices.map(\.total).reduce(0, +)
            let efficiency = totalAmount > 0 ? 1 - (Double(truncating: NSDecimalNumber(decimal: overdueAmount)) / Double(truncating: NSDecimalNumber(decimal: totalAmount))) : 1.0
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            return ChartDataPoint(
                label: formatter.string(from: monthStart),
                value: efficiency * 100,
                color: efficiency > 0.9 ? .green : (efficiency > 0.7 ? .orange : .red),
                date: monthStart
            )
        }.reversed()
    }
    
    func createCollectionHeatmap(invoices: [Invoice], currency: String) -> [HeatmapDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var heatmapData: [HeatmapDataPoint] = []
        
        // Create 7x4 heatmap for last 4 weeks
        for week in 0..<4 {
            for day in 0..<7 {
                let dayOffset = week * 7 + day
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                
                let dayInvoices = invoices.filter { 
                    calendar.isDate($0.issueDate, inSameDayAs: date)
                }
                
                let overdueCount = dayInvoices.filter { $0.status == .overdue }.count
                let totalCount = dayInvoices.count
                let efficiency = totalCount > 0 ? 1 - (Double(overdueCount) / Double(totalCount)) : 1.0
                
                heatmapData.append(HeatmapDataPoint(
                    x: day,
                    y: week,
                    value: efficiency,
                    color: efficiency > 0.9 ? .green.opacity(efficiency) : (efficiency > 0.7 ? .orange.opacity(efficiency) : .red.opacity(efficiency)),
                    label: "\(Int(efficiency * 100))%"
                ))
            }
        }
        
        return heatmapData
    }
    
    // Add more helper functions for other chart types...
    func createLTVChartData(invoices: [Invoice], currency: String) -> [ChartDataPoint] {
        // Implementation for LTV chart data
        return []
    }
    
    func createCustomerValueHeatmap(invoices: [Invoice], currency: String) -> [HeatmapDataPoint] {
        // Implementation for customer value heatmap
        return []
    }
    
    func createRetentionChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        // Implementation for retention chart data
        return []
    }
    
    func createRetentionHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        // Implementation for retention heatmap
        return []
    }
    
    func createTopCustomerChartData(customers: [CustomerSegment], currency: String) -> [ChartDataPoint] {
        return customers.prefix(5).map { customer in
            ChartDataPoint(
                label: customer.name,
                value: customer.revenue,
                color: .yellow,
                date: nil
            )
        }
    }
    
    func createCustomerContributionHeatmap(customers: [CustomerSegment]) -> [HeatmapDataPoint] {
        return customers.prefix(5).enumerated().map { index, customer in
            HeatmapDataPoint(
                x: index,
                y: 0,
                value: customer.percentage / 100,
                color: .yellow.opacity(customer.percentage / 100),
                label: "\(String(format: "%.1f", customer.percentage))%"
            )
        }
    }
    
    func createProcessingTimeChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        // Implementation for processing time chart data
        return []
    }
    
    func createProcessingTimeHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        // Implementation for processing time heatmap
        return []
    }
    
    func createPaymentSpeedChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        // Implementation for payment speed chart data
        return []
    }
    
    func createPaymentSpeedHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        // Implementation for payment speed heatmap
        return []
    }
    
    func createOverdueRateChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        // Implementation for overdue rate chart data
        return []
    }
    
    func createOverdueHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        // Implementation for overdue heatmap
        return []
    }
    
    func createMonthlyGrowthChartData(invoices: [Invoice], currency: String) -> [ChartDataPoint] {
        // Implementation for monthly growth chart data
        return []
    }
    
    func createGrowthTrendHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        // Implementation for growth trend heatmap
        return []
    }
    
    func createAcquisitionChartData(invoices: [Invoice]) -> [ChartDataPoint] {
        // Implementation for acquisition chart data
        return []
    }
    
    func createAcquisitionHeatmap(invoices: [Invoice]) -> [HeatmapDataPoint] {
        // Implementation for acquisition heatmap
        return []
    }
    
    func createRevenuePerCustomerChartData(invoices: [Invoice], currency: String) -> [ChartDataPoint] {
        // Implementation for revenue per customer chart data
        return []
    }
    
    func createRevenuePerCustomerHeatmap(invoices: [Invoice], currency: String) -> [HeatmapDataPoint] {
        // Implementation for revenue per customer heatmap
        return []
    }
    
    func createPaymentMethodChartData(paymentMethods: [(String, Int)]) -> [ChartDataPoint] {
        return paymentMethods.map { method, count in
            ChartDataPoint(
                label: method,
                value: Double(count),
                color: .blue,
                date: nil
            )
        }
    }
    
    func createPaymentMethodHeatmap(paymentMethods: [(String, Int)]) -> [HeatmapDataPoint] {
        let totalCount = paymentMethods.map(\.1).reduce(0, +)
        
        return paymentMethods.enumerated().map { index, method in
            let percentage = totalCount > 0 ? Double(method.1) / Double(totalCount) : 0
            return HeatmapDataPoint(
                x: index,
                y: 0,
                value: percentage,
                color: .blue.opacity(percentage),
                label: "\(method.1)"
            )
        }
    }
    
    func createPaymentTrendChartData(trends: [PaymentTrend], currency: String) -> [ChartDataPoint] {
        return trends.map { trend in
            ChartDataPoint(
                label: trend.period,
                value: trend.paid,
                color: .green,
                date: nil
            )
        }
    }
    
    func createPaymentTrendHeatmap(trends: [PaymentTrend]) -> [HeatmapDataPoint] {
        return trends.enumerated().map { index, trend in
            let total = trend.paid + trend.pending + trend.overdue
            let paidPercentage = total > 0 ? trend.paid / total : 0
            
            return HeatmapDataPoint(
                x: index,
                y: 0,
                value: paidPercentage,
                color: .green.opacity(paidPercentage),
                label: "\(Int(trend.paid))"
            )
        }
    }
    
    func createOutstandingChartData(invoices: [Invoice], currency: String) -> [ChartDataPoint] {
        // Implementation for outstanding chart data
        return []
    }
    
    func createOutstandingHeatmap(invoices: [Invoice], currency: String) -> [HeatmapDataPoint] {
        // Implementation for outstanding heatmap
        return []
    }
}

// MARK: - Fullscreen Cover Components

struct FullscreenMetricCoverView: View {
    let metric: AnalyticsMetric
    @Binding var isPresented: Bool
    @State private var animationProgress: Double = 0
    @State private var chartAnimationProgress: Double = 0
    @State private var heatmapAnimationProgress: Double = 0
    @State private var backgroundBlur: Double = 0
    @State private var contentOffset: CGFloat = 0
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        ZStack {
            // Background with blur effect - адаптировано для обеих тем
            (scheme == .dark ? Color.black : Color.white)
                .opacity(scheme == .dark ? 0.6 : 0.8)
                .ignoresSafeArea()
                .blur(radius: backgroundBlur)
                .animation(.easeInOut(duration: 0.3), value: backgroundBlur)
            
            // Main content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content with top padding
                ScrollView {
                    VStack(spacing: 24) {
                        // Metric overview
                        metricOverviewCard
                        
                        // Chart section
                        chartSection
                        
                        // Heatmap section
                        heatmapSection
                        
                        // Additional insights
                        insightsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .offset(y: contentOffset)
            .scaleEffect(animationProgress)
            .opacity(animationProgress)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animationProgress = 1.0
                backgroundBlur = 5
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                chartAnimationProgress = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.2).delay(0.4)) {
                heatmapAnimationProgress = 1.0
            }
            
            // Start continuous animations
            startContinuousAnimations()
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.3)) {
                animationProgress = 0
                backgroundBlur = 0
                contentOffset = 100
            }
        }
    }
    
    private func startContinuousAnimations() {
        // Background pulse animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            backgroundBlur = 15
        }
        
        // Content breathing animation
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            contentOffset = -5
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(scheme == .dark ? .white : .black)
            }
            
            Spacer()
            
            Text(metric.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(scheme == .dark ? .white : .black)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            (scheme == .dark ? Color.black : Color.white)
                .opacity(0.1)
        )
        .padding(.top, 10)
    }
    
    private var metricOverviewCard: some View {
        VStack(spacing: 16) {
            // Icon and value
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(metric.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: metric.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(metric.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.value)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(scheme == .dark ? .white : .black)
                    
                    if let subtitle = metric.subtitle {
                        Text(subtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(scheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(metric.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            // Trend indicator
            if let trend = metric.trend, let trendValue = metric.trendValue {
                HStack(spacing: 8) {
                    Image(systemName: trend == .up ? "arrow.up.right" : (trend == .down ? "arrow.down.right" : "minus"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(trend == .up ? .green : (trend == .down ? .red : .gray))
                    
                    Text("\(String(format: "%.1f", trendValue))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(trend == .up ? .green : (trend == .down ? .red : .gray))
                    
                    Text("vs previous period")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(scheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(scheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Chart")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(scheme == .dark ? .white : .black)
            
            AnimatedChartView(
                data: metric.chartData,
                chartType: .line
            )
            .frame(height: 200)
            .scaleEffect(x: chartAnimationProgress, y: 1)
            .opacity(chartAnimationProgress)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heatmap Visualization")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(scheme == .dark ? .white : .black)
            
            // Heatmap explanation
            Text("Each cell represents data intensity - darker colors indicate higher values. This visualization helps identify patterns and trends in your data over time.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(scheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
                .lineSpacing(2)
            
            // Convert heatmap data to chart data for visualization
            let heatmapChartData = metric.heatmapData.map { heatmapPoint in
                ChartDataPoint(
                    label: heatmapPoint.label ?? "",
                    value: heatmapPoint.value,
                    color: heatmapPoint.color,
                    date: nil
                )
            }
            
            AnimatedChartView(
                data: heatmapChartData,
                chartType: .heatmap
            )
            .frame(height: 120)
            .scaleEffect(heatmapAnimationProgress)
            .opacity(heatmapAnimationProgress)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Explanation")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(scheme == .dark ? .white : .black)
            
            Text(metric.detailedExplanation)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Metric Card Component

struct EnhancedAnalyticsMetricCard: View {
    let metric: AnalyticsMetric
    let onTap: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with icon and premium badge
                HStack {
                    ZStack {
                        Circle()
                            .fill(metric.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: metric.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(metric.color)
                    }
                    
                    Spacer()
                    
                    if metric.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(scheme == .dark ? .white : .black)
                            .opacity(0.9)
                    }
                }
                .frame(height: 40)
                
                // Value and title
                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.value)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(height: 28)
                    
                    Text(metric.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 36)
                    
                    if let subtitle = metric.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .frame(height: 18)
                    } else {
                        Spacer()
                            .frame(height: 18)
                    }
                }
                .frame(height: 82)
                
                // Fixed spacing
                Spacer()
                    .frame(height: 12)
                
                // Trend indicator
                if let trend = metric.trend, let trendValue = metric.trendValue {
                    HStack(spacing: 6) {
                        Image(systemName: trend == .up ? "arrow.up.right" : (trend == .down ? "arrow.down.right" : "minus"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(trend == .up ? .green : (trend == .down ? .red : .gray))
                        
                        Text("\(String(format: "%.1f", trendValue))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(trend == .up ? .green : (trend == .down ? .red : .gray))
                    }
                    .frame(height: 24)
                } else {
                    Spacer()
                        .frame(height: 24)
                }
                
                // Mini heatmap preview
                if !metric.heatmapData.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(metric.heatmapData.prefix(6)) { dataPoint in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(dataPoint.color)
                                .frame(width: 10, height: 10)
                        }
                        
                        if metric.heatmapData.count > 6 {
                            Text("...")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 16)
                } else {
                    Spacer()
                        .frame(height: 16)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(metric.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Screen

struct AnalyticsScreen: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var vm = AnalyticsVM()
    @Environment(\.colorScheme) private var scheme
    
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var floatingElements: [FloatingElement] = []
    @State private var showPaywall = false
    @State private var selectedMetric: AnalyticsMetric?
    @State private var showFullscreenCover = false
    @State private var allMetrics: [AnalyticsMetric] = []
    @State private var cardAnimations: [UUID: Bool] = [:]
    @State private var pulseAnimations: [UUID: Bool] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                backgroundView
                
                // Floating elements
                ForEach(floatingElements) { element in
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .scaleEffect(element.scale)
                        .opacity(element.opacity)
                        .rotationEffect(.degrees(element.rotation))
                        .position(x: element.x, y: element.y)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: element.scale)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UI.largeSpacing) {
                        // Header с анимациями
                        headerView
                        
                        // Timeframe Selector (Premium)
                        if subscriptionManager.isPro {
                            timeframeSelector
                        }
                        
                        // Premium Metrics (Legacy)
                        if subscriptionManager.isPro {
                            premiumMetricsSection
                        } else {
                            premiumUpgradeSection
                        }
                        
                        // Enhanced Metrics Grid
                        enhancedMetricsSection
                            .padding(.top, 8)
                    }
                    .adaptiveContent()
                    .padding(.top, 16)
                }
                
                // Fullscreen Cover
                if showFullscreenCover, let metric = selectedMetric {
                    FullscreenMetricCoverView(
                        metric: metric,
                        isPresented: $showFullscreenCover
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
                    .zIndex(1000)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallScreen(onClose: { showPaywall = false })
                .environmentObject(subscriptionManager)
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            createFloatingElements()
            loadMetrics()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Analytics")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.primary)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    .offset(y: showContent ? 0 : -20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.7).delay(0.1), value: showContent)
                
                Text("Track your business performance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: showContent ? 0 : -15)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).delay(0.2), value: showContent)
            }
            Spacer()
            
                    if !subscriptionManager.isPro {
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Premium")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary)
                    )
                    .foregroundColor(scheme == .light ? .white : .black)
                }
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: showContent)
            }
        }
    }
    
    // MARK: - Timeframe Selector (Premium)
    
    private var timeframeSelector: some View {
        HStack(spacing: 12) {
            ForEach(AnalyticsVM.TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: { vm.selectedTimeframe = timeframe }) {
                    Text(timeframe.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(vm.selectedTimeframe == timeframe ? Color.primary : Color.clear)
                        )
                        .foregroundColor(vm.selectedTimeframe == timeframe ? (scheme == .light ? .white : .black) : .primary)
                }
            }
        }
        .padding(.horizontal, 4)
        .offset(y: showContent ? 0 : -10)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).delay(0.4), value: showContent)
    }
    
    // MARK: - Enhanced Metrics Section
    
    private var enhancedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Metrics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Tap any metric for detailed insights")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Tap for details hint
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Tap for details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .offset(y: showContent ? 0 : -10)
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.3), value: showContent)
            
            // Additional spacing between header and grid
            Spacer()
                .frame(height: 8)
            
            // Metrics grid
            VStack(spacing: 32) {
                ForEach(0..<((allMetrics.count + 1) / 2), id: \.self) { rowIndex in
                    HStack(spacing: 16) {
                        // Left card
                        if rowIndex * 2 < allMetrics.count {
                            let leftMetric = allMetrics[rowIndex * 2]
                            EnhancedAnalyticsMetricCard(metric: leftMetric) {
                                selectedMetric = leftMetric
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showFullscreenCover = true
                                }
                            }
                            .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 180)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(cardAnimations[leftMetric.id] ?? false ? 1.0 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .delay(0.4 + Double(rowIndex * 2) * 0.1),
                                value: showContent
                            )
                            .animation(
                                .easeInOut(duration: 0.8)
                                .delay(Double(rowIndex * 2) * 0.1),
                                value: cardAnimations[leftMetric.id] ?? false
                            )
                        } else {
                            Spacer()
                                .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 180)
                        }
                        
                        // Right card
                        if rowIndex * 2 + 1 < allMetrics.count {
                            let rightMetric = allMetrics[rowIndex * 2 + 1]
                            EnhancedAnalyticsMetricCard(metric: rightMetric) {
                                selectedMetric = rightMetric
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showFullscreenCover = true
                                }
                            }
                            .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 180)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(cardAnimations[rightMetric.id] ?? false ? 1.0 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .delay(0.4 + Double(rowIndex * 2 + 1) * 0.1),
                                value: showContent
                            )
                            .animation(
                                .easeInOut(duration: 0.8)
                                .delay(Double(rowIndex * 2 + 1) * 0.1),
                                value: cardAnimations[rightMetric.id] ?? false
                            )
                        } else {
                            Spacer()
                                .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 180)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Free Metrics Section (Legacy)
    
    private var freeMetricsSection: some View {
        VStack(spacing: 16) {
            // Main Stats Cards
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Total Invoices",
                    value: String(vm.totalInvoices(app.invoices)),
                    subtitle: "\(vm.paidInvoices(app.invoices)) paid",
                    icon: "doc.text",
                    tint: .blue,
                    isPremium: false
                )
                
                AnalyticsStatCard(
                    title: "Total Revenue",
                    value: Money.fmt(vm.totalRevenue(app.invoices), code: app.currency),
                    subtitle: "From paid invoices",
                    icon: "dollarsign.circle",
                    tint: .green,
                    isPremium: false
                )
            }
            
            // Secondary Stats
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    title: "Unique Clients",
                    value: String(vm.uniqueClients(app.invoices)),
                    subtitle: "Active customers",
                    icon: "person.2",
                    tint: .purple,
                    isPremium: false
                )
                
                AnalyticsStatCard(
                    title: "Avg Invoice",
                    value: Money.fmt(vm.avgInvoiceValue(app.invoices), code: app.currency),
                    subtitle: "Per invoice",
                    icon: "chart.bar",
                    tint: .orange,
                    isPremium: false
                )
            }
            
            // Status Breakdown
            HStack(spacing: 12) {
                StatusCard(
                    title: "Paid",
                    count: vm.paidInvoices(app.invoices),
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatusCard(
                    title: "Pending",
                    count: vm.pendingInvoices(app.invoices),
                    color: .blue,
                    icon: "clock.fill"
                )
             
                StatusCard(
                    title: "Overdue",
                    count: vm.overdueInvoices(app.invoices),
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).delay(0.5), value: showContent)
    }
    
    // MARK: - Premium Metrics Section
    
    private var premiumMetricsSection: some View {
        VStack(spacing: 20) {
            // Revenue Growth Card
            RevenueGrowthCard(
                growth: vm.revenueGrowth(app.invoices),
                currentRevenue: vm.totalRevenue(app.invoices),
                currency: app.currency
            )
            
            // Revenue Chart
            RevenueChartCard(
                data: vm.monthlyRevenueData(app.invoices),
                currency: app.currency
            )
            
            // Top Customers
            TopCustomersCard(
                customers: vm.topCustomers(app.invoices),
                currency: app.currency
            )
            
            // Payment Trends
            PaymentTrendsCard(
                trends: vm.paymentTrends(app.invoices),
                currency: app.currency
            )
            
            // Advanced Metrics
            HStack(spacing: 12) {
                AdvancedMetricCard(
                    title: "Payment Rate",
                    value: "\(Int(vm.paymentRate(app.invoices) * 100))%",
                    icon: "percent",
                    color: .green
                )
                
                AdvancedMetricCard(
                    title: "Invoice Velocity",
                    value: String(format: "%.1f", vm.invoiceVelocity(app.invoices)),
                    subtitle: "per month",
                    icon: "speedometer",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                AdvancedMetricCard(
                    title: "Customer LTV",
                    value: Money.fmt(vm.customerLifetimeValue(app.invoices), code: app.currency),
                    icon: "person.crop.circle",
                    color: .purple
                )
                
                AdvancedMetricCard(
                    title: "Conversion Rate",
                    value: "\(Int(vm.paymentRate(app.invoices) * 100))%",
                    subtitle: "draft to paid",
                    icon: "arrow.right.circle",
                    color: .orange
                )
            }
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).delay(0.6), value: showContent)
    }
    
    // MARK: - Premium Upgrade Section
    
    private var premiumUpgradeSection: some View {
        VStack(spacing: 20) {
            // Premium Features Preview
            VStack(spacing: 16) {
                    HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    Text("Unlock Advanced Analytics")
                        .font(.system(size: 20, weight: .bold))
                        Spacer()
                }
                
                VStack(spacing: 12) {
                    PremiumFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Revenue Trends & Growth",
                        description: "Track your business growth over time"
                    )
                    
                    PremiumFeatureRow(
                        icon: "person.3.sequence",
                        title: "Customer Analytics",
                        description: "Identify your top customers and segments"
                    )
                    
                    PremiumFeatureRow(
                        icon: "chart.bar.xaxis",
                        title: "Payment Performance",
                        description: "Monitor payment trends and patterns"
                    )
                    
                    PremiumFeatureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Detailed Reports",
                        description: "Export comprehensive analytics data"
                    )
                }
                
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Upgrade to Premium")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                    )
                    .foregroundColor(scheme == .light ? .white : .black)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).delay(0.7), value: showContent)
    }
}

// MARK: - Background View

extension AnalyticsScreen {
    private var backgroundView: some View {
        Group {
            if scheme == .light {
                ZStack {
                    // Основной градиент
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.97), Color(white: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент с анимацией
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.96), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Анимированный shimmer эффект
                    
                    // Плавающие световые пятна
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 200, height: 200)
                            .position(
                                x: CGFloat(100 + i * 150),
                                y: CGFloat(200 + i * 100)
                            )
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .opacity(pulseAnimation ? 0.6 : 0.3)
                            .animation(
                                .easeInOut(duration: 3.0 + Double(i) * 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pulseAnimation
                            )
                    }
                }
            } else {
                ZStack {
                    // Основной градиент для темной темы
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Радиальный градиент
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 520
                    )
                    .blendMode(.screen)
                    
                    // Анимированный shimmer эффект для темной темы
                    
                    // Плавающие световые пятна для темной темы
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 240, height: 240)
                            .position(
                                x: CGFloat(120 + i * 180),
                                y: CGFloat(180 + i * 120)
                            )
                            .scaleEffect(pulseAnimation ? 1.3 : 0.7)
                            .opacity(pulseAnimation ? 0.8 : 0.4)
                            .animation(
                                .easeInOut(duration: 4.0 + Double(i) * 0.7)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.4),
                                value: pulseAnimation
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Animation Functions
    
    
    private func createFloatingElements() {
        floatingElements = (0..<5).map { _ in
            FloatingElement(
                x: Double.random(in: 50...350),
                y: Double.random(in: 100...600),
                opacity: Double.random(in: 0.3...0.7),
                scale: Double.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func loadMetrics() {
        allMetrics = vm.getAllMetrics(for: app.invoices, currency: app.currency)
        
        // Initialize animation states for each metric
        for metric in allMetrics {
            cardAnimations[metric.id] = false
            pulseAnimations[metric.id] = false
        }
        
        // Start staggered animations
        startStaggeredAnimations()
    }
    
    private func startStaggeredAnimations() {
        for (index, metric) in allMetrics.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    cardAnimations[metric.id] = true
                }
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1 + 0.4) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseAnimations[metric.id] = true
                }
            }
        }
    }
}

// MARK: - Chart Components

struct AnimatedChartView: View {
    let data: [ChartDataPoint]
    let chartType: ChartType
    @State private var animationProgress: Double = 0
    
    var body: some View {
        Group {
            switch chartType {
            case .line:
                LineChartView(data: data, animationProgress: animationProgress)
            case .bar:
                BarChartView(data: data, animationProgress: animationProgress)
            case .pie:
                PieChartView(data: data, animationProgress: animationProgress)
            case .radar:
                RadarChartView(data: data, animationProgress: animationProgress)
            case .heatmap:
                HeatmapChartView(data: data, animationProgress: animationProgress)
            case .donut:
                DonutChartView(data: data, animationProgress: animationProgress)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
}

struct LineChartView: View {
    let data: [ChartDataPoint]
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.map(\.value).max() ?? 1
            let minValue = data.map(\.value).min() ?? 0
            let range = maxValue - minValue
            
            ZStack {
                // Grid lines
                ForEach(0..<5) { i in
                    let y = CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height * y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * y))
                    }
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                
                // Data line
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) / CGFloat(max(1, data.count - 1)) * geometry.size.width
                        let y = geometry.size.height - (CGFloat(point.value - minValue) / CGFloat(range)) * geometry.size.height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: animationProgress)
                .stroke(
                    LinearGradient(
                        colors: data.map(\.color),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Data points
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let x = CGFloat(index) / CGFloat(max(1, data.count - 1)) * geometry.size.width
                    let y = geometry.size.height - (CGFloat(point.value - minValue) / CGFloat(range)) * geometry.size.height
                    
                    Circle()
                        .fill(point.color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                        .scaleEffect(animationProgress)
                        .opacity(animationProgress)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: animationProgress)
                }
            }
        }
    }
}

struct BarChartView: View {
    let data: [ChartDataPoint]
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.map(\.value).max() ?? 1
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(point.color)
                            .frame(
                                width: max(4, geometry.size.width / CGFloat(data.count) - 4),
                                height: (CGFloat(point.value) / CGFloat(maxValue)) * geometry.size.height * animationProgress
                            )
                            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: animationProgress)
                        
                        Text(point.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
        }
    }
}

struct PieChartView: View {
    let data: [ChartDataPoint]
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let total = data.map(\.value).reduce(0, +)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            
            ZStack {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let startAngle = data.prefix(index).map(\.value).reduce(0, +) / total * 2 * .pi - .pi / 2
                    let endAngle = data.prefix(index + 1).map(\.value).reduce(0, +) / total * 2 * .pi - .pi / 2
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .radians(startAngle),
                            endAngle: .radians(endAngle),
                            clockwise: false
                        )
                        path.closeSubpath()
                    }
                    .fill(point.color)
                    .scaleEffect(animationProgress)
                    .opacity(animationProgress)
                    .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: animationProgress)
                }
            }
        }
    }
}

struct RadarChartView: View {
    let data: [ChartDataPoint]
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            let maxValue = data.map(\.value).max() ?? 1
            
            ZStack {
                // Grid circles
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: radius * 2 * CGFloat(i + 1) / 5)
                        .position(center)
                }
                
                // Data polygon
                RadarPolygon(
                    data: data,
                    center: center,
                    radius: radius,
                    maxValue: maxValue,
                    animationProgress: animationProgress
                )
                
                // Data points
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    RadarPoint(
                        data: data,
                        index: index,
                        center: center,
                        radius: radius,
                        maxValue: maxValue,
                        animationProgress: animationProgress
                    )
                }
            }
        }
    }
}

struct RadarPolygon: View {
    let data: [ChartDataPoint]
    let center: CGPoint
    let radius: CGFloat
    let maxValue: Double
    let animationProgress: Double
    
    var body: some View {
        Path { path in
            for (index, point) in data.enumerated() {
                let angle = 2 * .pi * CGFloat(index) / CGFloat(data.count) - .pi / 2
                let value = CGFloat(point.value) / CGFloat(maxValue)
                let x = center.x + cos(angle) * radius * value
                let y = center.y + sin(angle) * radius * value
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: data.map(\.color),
                startPoint: .center,
                endPoint: .bottom
            ).opacity(0.3)
        )
        .scaleEffect(animationProgress)
        .opacity(animationProgress)
    }
}

struct RadarPoint: View {
    let data: [ChartDataPoint]
    let index: Int
    let center: CGPoint
    let radius: CGFloat
    let maxValue: Double
    let animationProgress: Double
    
    var body: some View {
        let point = data[index]
        let angle = 2 * .pi * CGFloat(index) / CGFloat(data.count) - .pi / 2
        let value = CGFloat(point.value) / CGFloat(maxValue)
        let x = center.x + cos(angle) * radius * value
        let y = center.y + sin(angle) * radius * value
        
        Circle()
            .fill(point.color)
            .frame(width: 8, height: 8)
            .position(x: x, y: y)
            .scaleEffect(animationProgress)
            .opacity(animationProgress)
            .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: animationProgress)
    }
}

struct HeatmapChartView: View {
    let data: [ChartDataPoint]
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let columns = 7
            let cellHeight = geometry.size.height / CGFloat(max(1, data.count / columns))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columns), spacing: 2) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(point.color)
                        .frame(height: cellHeight)
                        .scaleEffect(animationProgress)
                        .opacity(animationProgress)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .delay(Double(index) * 0.05),
                            value: animationProgress
                        )
                }
            }
        }
    }
}

struct DonutChartView: View {
    let data: [ChartDataPoint]
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = min(geometry.size.width, geometry.size.height) / 2 - 20
            let innerRadius = outerRadius * 0.6
            
            ZStack {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    DonutSegment(
                        data: data,
                        index: index,
                        center: center,
                        outerRadius: outerRadius,
                        innerRadius: innerRadius,
                        animationProgress: animationProgress
                    )
                }
            }
        }
    }
}

struct DonutSegment: View {
    let data: [ChartDataPoint]
    let index: Int
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let animationProgress: Double
    
    var body: some View {
        let total = data.map(\.value).reduce(0, +)
        let startAngle = data.prefix(index).map(\.value).reduce(0, +) / total * 2 * .pi - .pi / 2
        let endAngle = data.prefix(index + 1).map(\.value).reduce(0, +) / total * 2 * .pi - .pi / 2
        let point = data[index]
        
        Path { path in
            path.addArc(
                center: center,
                radius: outerRadius,
                startAngle: .radians(startAngle),
                endAngle: .radians(endAngle),
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: .radians(endAngle),
                endAngle: .radians(startAngle),
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(point.color)
        .scaleEffect(animationProgress)
        .opacity(animationProgress)
        .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: animationProgress)
    }
}

// MARK: - UI Components

private struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isPremium: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint)
                
                if isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tint.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(tint.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(String(count))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct RevenueGrowthCard: View {
    let growth: Double
    let currentRevenue: Decimal
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(growth >= 0 ? .green : .red)
                
                Text("Revenue Growth")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(abs(growth), specifier: "%.1f")%")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(growth >= 0 ? .green : .red)
            }
            
            Text(Money.fmt(currentRevenue, code: currency))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct RevenueChartCard: View {
    let data: [RevenueData]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                    HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Monthly Revenue")
                    .font(.system(size: 16, weight: .semibold))
                
                        Spacer()
            }
            
            if #available(iOS 16.0, *) {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Revenue", item.revenue)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS < 16
                VStack(spacing: 8) {
                    ForEach(data) { item in
                        HStack {
                            Text(item.month)
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 40, alignment: .leading)
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: max(4, geometry.size.width * (item.revenue / (data.map(\.revenue).max() ?? 1))))
                            }
                            .frame(height: 20)
                            
                            Text(Money.fmt(Decimal(item.revenue), code: currency))
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct TopCustomersCard: View {
    let customers: [CustomerSegment]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                Text("Top Customers")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(customers) { customer in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.name)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            
                            Text("\(customer.invoices) invoices")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Money.fmt(Decimal(customer.revenue), code: currency))
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("\(customer.percentage, specifier: "%.1f")%")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.05))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct PaymentTrendsCard: View {
    let trends: [PaymentTrend]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
                
                Text("Payment Trends")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(trends) { trend in
                    HStack {
                        Text(trend.period)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 60, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(Money.fmt(Decimal(trend.paid), code: currency))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text(Money.fmt(Decimal(trend.pending), code: currency))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text(Money.fmt(Decimal(trend.overdue), code: currency))
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

private struct AdvancedMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}
