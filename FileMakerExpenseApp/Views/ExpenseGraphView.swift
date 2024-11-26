import SwiftUI
import Charts
import SwiftData

struct FinancialData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let color: Color
}

struct ExpenseGraphView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    private var financialData: [FinancialData] {
        let filteredExpenses = filterExpenses(expenses)
        
        let totalIncome = filteredExpenses
            .filter { $0.category == .income }
            .reduce(0) { $0 + $1.amount }
        
        let totalPaidExpenses = filteredExpenses
            .filter { $0.category != .income && $0.isPaid }
            .reduce(0) { $0 + $1.amount }
        
        let totalUnpaidExpenses = filteredExpenses
            .filter { $0.category != .income && !$0.isPaid }
            .reduce(0) { $0 + $1.amount }
        
        let remaining = totalIncome - totalPaidExpenses
        let totalExpenses = totalPaidExpenses + totalUnpaidExpenses
        
        return [
            FinancialData(category: "Income", amount: totalIncome, color: .green),
            FinancialData(category: "Remaining", amount: remaining, color: remaining < 0 ? .red : .blue),
            FinancialData(category: "Total Expenses", amount: totalExpenses, color: .red),
            FinancialData(category: "Paid", amount: totalPaidExpenses, color: .orange),
            FinancialData(category: "Unpaid", amount: totalUnpaidExpenses, color: .purple)
        ]
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Overview")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(financialData) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(item.color)
                .annotation(position: .top) {
                    Text(item.amount, format: .currency(code: "USD"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 200)
            .padding()
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(financialData) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text(item.category)
                            .font(.caption)
                        Spacer()
                        Text(item.amount, format: .currency(code: "USD"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
    }
}

#Preview {
    ExpenseGraphView(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, isPaid: true, category: .rent),
            Expense(name: "Groceries", amount: 500, isPaid: false, category: .groceries)
        ],
        selectedPeriod: .thisMonth
    )
} 