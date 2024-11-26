import SwiftUI
import Charts

struct SavingsGoalsView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    @State private var isAnimating = true
    
    struct SavingsData: Identifiable {
        let id = UUID()
        let date: Date
        let income: Double
        let expenses: Double
        let savings: Double
        let savingsRate: Double
        
        var formattedDate: String {
            date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private var savingsData: [SavingsData] {
        let calendar = Calendar.current
        let filteredExpenses = filterExpenses(expenses)
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        return grouped.map { date, dayExpenses in
            let income = dayExpenses
                .filter { $0.category == .income }
                .reduce(0) { $0 + $1.amount }
            let expenses = dayExpenses
                .filter { $0.category != .income }
                .reduce(0) { $0 + $1.amount }
            let savings = income - expenses
            let savingsRate = income > 0 ? (savings / income) * 100 : 0
            
            return SavingsData(
                date: date,
                income: income,
                expenses: expenses,
                savings: savings,
                savingsRate: savingsRate
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    private var totalSavings: Double {
        savingsData.reduce(0) { $0 + $1.savings }
    }
    
    private var averageSavingsRate: Double {
        let totalIncome = savingsData.reduce(0) { $0 + $1.income }
        return totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Savings Progress Card
                VStack(spacing: 8) {
                    Text("Total Savings")
                        .font(.headline)
                    Text(totalSavings, format: .currency(code: "USD"))
                        .font(.title)
                        .foregroundColor(totalSavings >= 0 ? .green : .red)
                    Text("Average Savings Rate: \(averageSavingsRate, specifier: "%.1f")%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Savings Trend Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Savings Trend")
                        .font(.headline)
                    
                    Chart {
                        ForEach(savingsData) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Savings", isAnimating ? data.savings : 0)
                            )
                            .foregroundStyle(data.savings >= 0 ? .green : .red)
                            
                            AreaMark(
                                x: .value("Date", data.date),
                                y: .value("Savings", isAnimating ? max(data.savings, 0) : 0)
                            )
                            .foregroundStyle(.green.opacity(0.1))
                            
                            AreaMark(
                                x: .value("Date", data.date),
                                y: .value("Losses", isAnimating ? min(data.savings, 0) : 0)
                            )
                            .foregroundStyle(.red.opacity(0.1))
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Daily Breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Breakdown")
                        .font(.headline)
                    
                    ForEach(savingsData.reversed()) { data in
                        HStack {
                            Text(data.formattedDate)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if data.income > 0 {
                                    Text("Income: \(data.income, format: .currency(code: "USD"))")
                                        .foregroundColor(.green)
                                }
                                if data.expenses > 0 {
                                    Text("Expenses: \(data.expenses, format: .currency(code: "USD"))")
                                        .foregroundColor(.red)
                                }
                                Text("Savings: \(data.savings, format: .currency(code: "USD"))")
                                    .foregroundColor(data.savings >= 0 ? .green : .red)
                                    .bold()
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
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
        .navigationTitle("Savings Goals")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

#Preview {
    SavingsGoalsView(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, category: .rent),
            Expense(name: "Groceries", amount: 500, category: .groceries)
        ],
        selectedPeriod: .thisMonth
    )
} 