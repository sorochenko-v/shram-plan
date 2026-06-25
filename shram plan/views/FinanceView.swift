import SwiftUI
import Charts
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Data Models

enum TransactionType: String, CaseIterable, Codable {
    case inflow
    case expense
}

struct FinancialTransaction: Identifiable, Equatable {
    let id: UUID
    var type: TransactionType
    var category: String
    var amount: Double
    var date: Date

    init(id: UUID = UUID(), type: TransactionType, category: String, amount: Double, date: Date = Date()) {
        self.id = id
        self.type = type
        self.category = category
        self.amount = amount
        self.date = date
    }
}

struct CategoryTotal: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
}

// MARK: - FinanceView

struct FinanceView: View {
    @State private var transactions: [FinancialTransaction] = FinanceView.mockData
    @State private var showLogIncome = false
    @State private var showLogExpense = false

    private var totalInflows: Double {
        transactions.filter { $0.type == .inflow }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var netRemainder: Double {
        totalInflows - totalExpenses
    }

    private var savingsTarget: Double {
        totalInflows * 0.2
    }

    private var efficiencyRatio: Double {
        guard totalInflows > 0 else { return 0 }
        return min(totalExpenses / totalInflows, 1.5)
    }

    private var expensesByCategory: [CategoryTotal] {
        Dictionary(grouping: transactions.filter { $0.type == .expense }, by: \.category)
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    private var inflowsByCategory: [CategoryTotal] {
        Dictionary(grouping: transactions.filter { $0.type == .inflow }, by: \.category)
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 28) {

                // MARK: Custom Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Financial Analytics")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Track inflows, control expenses, build wealth.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 4)
                .padding(.top, 16)

                // MARK: Efficiency Banner
                efficiencyBanner

                // MARK: Summary Cards
                summaryCards

                // MARK: Expense Allocation Chart
                expenseChart

                // MARK: Inflow Distribution Chart
                inflowChart

                // MARK: Quick Actions
                quickActions

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(
            ZStack {
                Color(uiColor: .systemBackground)
                LinearGradient(
                    colors: [Color.primary.opacity(0.008), Color.primary.opacity(0.004)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogIncome) {
            LogTransactionSheet(type: .inflow) { transaction in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    transactions.insert(transaction, at: 0)
                }
            }
        }
        .sheet(isPresented: $showLogExpense) {
            LogTransactionSheet(type: .expense) { transaction in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    transactions.insert(transaction, at: 0)
                }
            }
        }
    }

    // MARK: - Efficiency Banner

    private var efficiencyBanner: some View {
        let percentage = totalInflows > 0 ? (totalExpenses / totalInflows) * 100 : 0
        let isOverspent = totalExpenses > totalInflows

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("SPENDING EFFICIENCY")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(isOverspent ? .scarlet : .forest)
                    .tracking(1.6)

                Spacer()

                Text(String(format: "%.0f%%", min(percentage, 150)))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(isOverspent ? .scarlet : .primary)
                +
                Text(" of inflows")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isOverspent
                                    ? [.scarlet.opacity(0.9), .scarlet]
                                    : [.forest.opacity(0.7), .forest],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(CGFloat(efficiencyRatio), 1.0), height: 10)
                        .shadow(color: isOverspent ? .scarlet.opacity(0.3) : .forest.opacity(0.2), radius: 6, y: 2)
                }
            }
            .frame(height: 10)

            HStack {
                Text(formatCurrency(totalExpenses))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.scarlet)

                Text("spent of")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Text(formatCurrency(totalInflows))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.forest)

                Text("earned")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isOverspent ? Color.scarlet.opacity(0.12) : Color.primary.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                SummaryMetricCard(
                    label: "Total Inflows",
                    value: formatCurrency(totalInflows),
                    accent: .forest,
                    icon: "arrow.down.left"
                )

                SummaryMetricCard(
                    label: "Total Expenses",
                    value: formatCurrency(totalExpenses),
                    accent: .scarlet,
                    icon: "arrow.up.right"
                )
            }

            SummaryMetricCard(
                label: "Net Remainder",
                value: formatCurrency(netRemainder),
                accent: .matteGold,
                icon: "building.columns",
                subtitle: "20% savings target: \(formatCurrency(savingsTarget))",
                isMet: netRemainder >= savingsTarget
            )
        }
    }

    // MARK: - Expense Chart

    private var expenseChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXPENSE ALLOCATION")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.scarlet.opacity(0.85))
                .tracking(1.6)
                .padding(.leading, 4)

            Chart(expensesByCategory) { item in
                BarMark(
                    x: .value("Amount", item.total),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.scarlet.opacity(0.75), Color(uiColor: .systemGray2).opacity(0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(5)
                .annotation(position: .trailing, spacing: 6) {
                    Text(formatCurrency(item.total))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
            }
            .frame(height: CGFloat(expensesByCategory.count) * 44 + 20)
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Inflow Chart

    private var inflowChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("INFLOW DISTRIBUTION")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.forest.opacity(0.85))
                .tracking(1.6)
                .padding(.leading, 4)

            Chart(inflowsByCategory) { item in
                BarMark(
                    x: .value("Amount", item.total),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.forest.opacity(0.8), .forest.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(5)
                .annotation(position: .trailing, spacing: 6) {
                    Text(formatCurrency(item.total))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
            }
            .frame(height: CGFloat(inflowsByCategory.count) * 44 + 20)
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 14) {
            Button {
                triggerHaptic()
                showLogIncome = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Log Income")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.forest)
                )
                .shadow(color: Color.forest.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Button {
                triggerHaptic()
                showLogExpense = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Log Expense")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.scarlet)
                )
                .shadow(color: Color.scarlet.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    // MARK: - Mock Data

    static let mockData: [FinancialTransaction] = [
        // Inflows
        FinancialTransaction(type: .inflow, category: "Business", amount: 4200),
        FinancialTransaction(type: .inflow, category: "Business", amount: 3100),
        FinancialTransaction(type: .inflow, category: "Passive Income", amount: 950),
        FinancialTransaction(type: .inflow, category: "Debt Repaid", amount: 600),
        FinancialTransaction(type: .inflow, category: "Other", amount: 320),
        // Expenses
        FinancialTransaction(type: .expense, category: "Housing", amount: 1850),
        FinancialTransaction(type: .expense, category: "Family", amount: 920),
        FinancialTransaction(type: .expense, category: "Gas", amount: 380),
        FinancialTransaction(type: .expense, category: "Auto", amount: 540),
        FinancialTransaction(type: .expense, category: "Food & Drinks", amount: 780),
        FinancialTransaction(type: .expense, category: "Taxes", amount: 1400),
        FinancialTransaction(type: .expense, category: "Debts", amount: 650),
    ]
}

// MARK: - Summary Metric Card

struct SummaryMetricCard: View {
    let label: String
    let value: String
    let accent: Color
    let icon: String
    var subtitle: String? = nil
    var isMet: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accent)

                Text(label.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
            }

            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subtitle {
                HStack(spacing: 4) {
                    if let isMet {
                        Image(systemName: isMet ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isMet ? .forest : .scarlet)
                    }
                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Log Transaction Sheet

struct LogTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let type: TransactionType
    var onSave: (FinancialTransaction) -> Void

    @State private var amountText = ""
    @State private var selectedCategory: String = ""

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var accent: Color {
        type == .inflow ? .forest : .scarlet
    }

    private var categories: [String] {
        switch type {
        case .inflow: return ["Business", "Passive Income", "Debt Repaid", "Other"]
        case .expense: return ["Housing", "Family", "Gas", "Auto", "Food & Drinks", "Taxes", "Debts"]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.08))
                                .frame(width: 72, height: 72)

                            Image(systemName: type == .inflow ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(accent)
                        }

                        Text(type == .inflow ? "Log Income" : "Log Expense")
                            .font(.system(size: 26, weight: .bold, design: .rounded))

                        Text(type == .inflow ? "Record a new source of income." : "Track where your money is going.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Amount Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)

                        TextField("0.00", text: $amountText)
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .foregroundColor(accent)
                            .padding(18)
                            .background(Color.primary.opacity(0.02))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                    }

                    // Category Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                        selectedCategory = cat
                                    }
                                } label: {
                                    Text(cat)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedCategory == cat ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(selectedCategory == cat ? accent : Color.primary.opacity(0.03))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(selectedCategory == cat ? accent.opacity(0.3) : Color.primary.opacity(0.05), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let transaction = FinancialTransaction(
                        type: type,
                        category: selectedCategory.isEmpty ? categories[0] : selectedCategory,
                        amount: amount
                    )
                    onSave(transaction)
                    dismiss()
                } label: {
                    Text(type == .inflow ? "Save Income" : "Save Expense")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(accent)
                        .cornerRadius(16)
                        .shadow(color: accent.opacity(0.25), radius: 10, y: 5)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial)
                .disabled(amount <= 0)
                .opacity(amount <= 0 ? 0.45 : 1)
            }
            .onAppear {
                selectedCategory = categories[0]
            }
        }
    }
}

struct ImpulsePreset: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let englishTitle: String
    let color: Color

    var title: String {
        englishTitle
    }

    static let defaults: [ImpulsePreset] = [
        ImpulsePreset(emoji: "☕️", englishTitle: "Coffee", color: .brown),
        ImpulsePreset(emoji: "🚬", englishTitle: "Tobacco", color: .red),
        ImpulsePreset(emoji: "🍔", englishTitle: "Fast Food", color: .orange),
        ImpulsePreset(emoji: "🛍️", englishTitle: "Shopping", color: .purple),
        ImpulsePreset(emoji: "🎮", englishTitle: "Gaming", color: .blue)
    ]

    static var custom: ImpulsePreset {
        ImpulsePreset(
            emoji: "✨",
            englishTitle: "Avoided Impulse",
            color: .green
        )
    }
}

struct WillpowerLog: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var amount: Double
    var date: Date
}

struct DisciplinePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ImpulseTile: View {
    let preset: ImpulsePreset
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(preset.emoji)
                        .font(.system(size: 28))
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(preset.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Capture saved money")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(preset.color.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct LeakControlRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
                .frame(width: 42, height: 42)
                .background(Circle().fill(color.opacity(0.08)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

struct WillpowerTimelineRow: View {
    let log: WillpowerLog

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 2, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(log.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text(log.date, style: .time)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "+%.2f US$", log.amount))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.green)
        }
        .padding(13)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

struct AvoidedImpulseLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let preset: ImpulsePreset
    var onSave: (String, Double) -> Void

    @State private var amountText = ""
    @State private var title = ""

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    Text(preset.emoji)
                        .font(.system(size: 46))
                        .frame(width: 82, height: 82)
                        .background(Circle().fill(preset.color.opacity(0.1)))

                    Text(preset.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("How much did you save by skipping this today?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title", text: $title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .textFieldStyle(.plain)

                    Divider()

                    TextField("0.00 US$", text: $amountText)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .foregroundColor(.green)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.68))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )

                Spacer()

                Button {
                    onSave(title.isEmpty ? preset.title : title, amount)
                    dismiss()
                } label: {
                    Text("Save Discipline Win")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.green)
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .disabled(amount <= 0)
                .opacity(amount <= 0 ? 0.45 : 1)
            }
            .padding(20)
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                title = preset.title
            }
        }
    }
}

extension View {
    func financeCard(cornerRadius: CGFloat) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.035), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack {
        FinanceView()
    }
}
