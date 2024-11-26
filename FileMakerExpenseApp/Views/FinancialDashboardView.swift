import SwiftUI
import Charts

struct FinancialDashboardView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        QuickStatCard(title: "Income", amount: totalIncome, icon: "arrow.down.circle.fill", color: .green)
                        QuickStatCard(title: "Expenses", amount: totalExpenses, icon: "arrow.up.circle.fill", color: .red)
                        QuickStatCard(title: "Balance", amount: totalIncome - totalExpenses, icon: "dollarsign.circle.fill", color: .blue)
                        QuickStatCard(title: "Pending", amount: totalUnpaid, icon: "clock.fill", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Income vs Expenses Chart
                    DashboardChartCard(
                        title: "Income vs Expenses",
                        data: monthlyComparison
                    )
                    
                    // Category Breakdown
                    CategoryBreakdownCard(expenses: expenses)
                    
                    // Recent Transactions
                    RecentTransactionsCard(expenses: expenses)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
    
    // Computed Properties
    private var totalIncome: Double {
        filterExpenses(expenses)
            .filter { $0.category == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        filterExpenses(expenses)
            .filter { $0.category != .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalUnpaid: Double {
        filterExpenses(expenses)
            .filter { $0.category != .income && !$0.isPaid }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyComparison: [(date: Date, income: Double, expenses: Double)] {
        let calendar = Calendar.current
        let filteredExpenses = filterExpenses(expenses)
        let grouped = Dictionary(grouping: filteredExpenses) {
            calendar.startOfMonth(for: $0.date)
        }
        
        return grouped.map { date, expenses in
            let income = expenses.filter { $0.category == .income }.reduce(0) { $0 + $1.amount }
            let expenses = expenses.filter { $0.category != .income }.reduce(0) { $0 + $1.amount }
            return (date, income, expenses)
        }.sorted { $0.date < $1.date }
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

// Supporting Views
struct QuickStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Text(amount, format: .currency(code: "USD"))
                .font(.title2)
                .bold()
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DashboardChartCard: View {
    let title: String
    let data: [(date: Date, income: Double, expenses: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Chart {
                ForEach(data, id: \.date) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Income", item.income)
                    )
                    .foregroundStyle(.green)
                    
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Expenses", item.expenses)
                    )
                    .foregroundStyle(.red)
                }
            }
            .frame(height: 200)
            
            // Legend
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Income")
                
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Expenses")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CategoryBreakdownCard: View {
    let expenses: [Expense]
    
    var categoryData: [(category: ExpenseCategory, amount: Double)] {
        Dictionary(grouping: expenses.filter { $0.category != .income }) { $0.category }
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
            
            ForEach(categoryData, id: \.category) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundColor(Color(item.category.color))
                    Text(item.category.rawValue)
                    Spacer()
                    Text(item.amount, format: .currency(code: "USD"))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentTransactionsCard: View {
    let expenses: [Expense]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
            
            ForEach(expenses.prefix(5)) { expense in
                HStack {
                    Image(systemName: expense.category.icon)
                        .foregroundColor(Color(expense.category.color))
                    
                    VStack(alignment: .leading) {
                        Text(expense.name)
                        Text(expense.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(expense.amount, format: .currency(code: "USD"))
                        .foregroundColor(expense.category == .income ? .green : .primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 