import SwiftUI
import Charts

struct ReportsView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    private var filteredExpenses: [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
    
    private var reportSummary: (income: Double, expenses: Double, savings: Double) {
        let income = filteredExpenses
            .filter { $0.category == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expenses = filteredExpenses
            .filter { $0.category != .income }
            .reduce(0) { $0 + $1.amount }
        
        return (income, expenses, income - expenses)
    }
    
    private var categoryBreakdown: [(category: ExpenseCategory, amount: Double)] {
        Dictionary(grouping: filteredExpenses.filter { $0.category != .income }) { $0.category }
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Financial Summary Card
                    VStack(spacing: 12) {
                        Text("Financial Summary")
                            .font(.headline)
                        
                        HStack {
                            StatCard(
                                title: "Income",
                                amount: reportSummary.income,
                                color: .green
                            )
                            
                            StatCard(
                                title: "Expenses",
                                amount: reportSummary.expenses,
                                color: .red
                            )
                            
                            StatCard(
                                title: "Net",
                                amount: reportSummary.savings,
                                color: reportSummary.savings >= 0 ? .green : .red
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expense Categories")
                            .font(.headline)
                        
                        ForEach(categoryBreakdown, id: \.category) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundColor(Color(item.category.color))
                                Text(item.category.rawValue)
                                Spacer()
                                Text(item.amount, format: .currency(code: "USD"))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Transaction List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transactions")
                            .font(.headline)
                        
                        ForEach(filteredExpenses.sorted { $0.date > $1.date }) { expense in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(expense.name)
                                        .font(.subheadline)
                                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(expense.amount, format: .currency(code: "USD"))
                                        .foregroundColor(expense.category == .income ? .green : .primary)
                                    Text(expense.category.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle("Financial Report")
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(amount, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ReportsView(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, category: .rent),
            Expense(name: "Groceries", amount: 500, category: .groceries)
        ],
        selectedPeriod: .thisMonth
    )
} 