import SwiftUI
import Charts

struct TrendsAnalysisView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    private var filteredExpenses: [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
    
    private var monthlyTrends: [(month: Date, income: Double, expenses: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) {
            calendar.startOfMonth(for: $0.date)
        }
        
        return grouped.map { date, transactions in
            let income = transactions
                .filter { $0.category == .income }
                .reduce(0) { $0 + $1.amount }
            let expenses = transactions
                .filter { $0.category != .income }
                .reduce(0) { $0 + $1.amount }
            return (date, income, expenses)
        }.sorted { $0.month < $1.month }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly Trends Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Trends")
                            .font(.headline)
                        
                        Chart {
                            ForEach(monthlyTrends, id: \.month) { item in
                                LineMark(
                                    x: .value("Month", item.month),
                                    y: .value("Income", item.income)
                                )
                                .foregroundStyle(.green)
                                
                                LineMark(
                                    x: .value("Month", item.month),
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
                    
                    // Monthly Details
                    ForEach(monthlyTrends, id: \.month) { item in
                        HStack {
                            Text(item.month, format: .dateTime.month().year())
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Income: \(item.income, format: .currency(code: "USD"))")
                                    .foregroundColor(.green)
                                Text("Expenses: \(item.expenses, format: .currency(code: "USD"))")
                                    .foregroundColor(.red)
                                Text("Net: \(item.income - item.expenses, format: .currency(code: "USD"))")
                                    .foregroundColor(item.income >= item.expenses ? .green : .red)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .navigationTitle("Trends Analysis")
        }
    }
}

#Preview {
    TrendsAnalysisView(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, category: .rent),
            Expense(name: "Groceries", amount: 500, category: .groceries)
        ],
        selectedPeriod: .thisMonth
    )
} 