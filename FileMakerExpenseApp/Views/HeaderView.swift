import SwiftUI
import SwiftData

enum TimePeriod: String, CaseIterable {
    case all = "All"
    case thisMonth = "This Month"
    case thisWeek = "This Week"
    case today = "Today"
    
    func dateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate end of day by setting time to 23:59:59
        let endOfDay: Date = {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 23
            components.minute = 59
            components.second = 59
            return calendar.date(from: components) ?? now
        }()
        
        switch self {
        case .all:
            return (Date.distantPast, endOfDay)
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (startOfMonth, endOfDay)
        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (startOfWeek, endOfDay)
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return (startOfDay, endOfDay)
        }
    }
}

struct HeaderView: View {
    let balanceInfo: BalanceInfo
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var selectedPeriod: TimePeriod = .thisMonth
    
    // Calculate total income from income category entries
    private var totalIncome: Double {
        filterExpenses(expenses)
            .filter { $0.category == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Calculate total paid expenses (excluding income)
    private var totalPaidExpenses: Double {
        filterExpenses(expenses)
            .filter { $0.category != .income && $0.isPaid }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Calculate total unpaid expenses (excluding income)
    private var totalUnpaidExpenses: Double {
        filterExpenses(expenses)
            .filter { $0.category != .income && !$0.isPaid }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Calculate total expenses (all non-income categories)
    private var totalExpenses: Double {
        filterExpenses(expenses)
            .filter { $0.category != .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Period Picker
            Picker("Time Period", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Income and Remaining Balance Section
            HStack(spacing: 8) {
                BalanceCard(
                    title: "Total Income",
                    amount: totalIncome,
                    backgroundColor: .green.opacity(0.1),
                    textColor: .green
                )
                .frame(maxWidth: .infinity)
                
                BalanceCard(
                    title: "Remaining",
                    amount: totalIncome - totalPaidExpenses,
                    backgroundColor: (totalIncome - totalPaidExpenses) < 0 ? .red.opacity(0.1) : .green.opacity(0.1),
                    textColor: (totalIncome - totalPaidExpenses) < 0 ? .red : .primary
                )
                .frame(maxWidth: .infinity)
            }
            
            // All Expenses Section in one row
            HStack(spacing: 8) {
                BalanceCard(
                    title: "Total Expenses",
                    amount: totalExpenses,
                    backgroundColor: .red.opacity(0.1),
                    textColor: .red
                )
                .frame(maxWidth: .infinity)
                
                BalanceCard(
                    title: "Paid",
                    amount: totalPaidExpenses,
                    backgroundColor: .green.opacity(0.1)
                )
                .frame(maxWidth: .infinity)
                
                BalanceCard(
                    title: "Unpaid",
                    amount: totalUnpaidExpenses,
                    backgroundColor: .red.opacity(0.1)
                )
                .frame(maxWidth: .infinity)
            }
            
            // Overdraw Warning if applicable
            let potentialOverdraw = totalIncome - (totalPaidExpenses + totalUnpaidExpenses)
            if potentialOverdraw < 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Potential overdraw: ")
                        .foregroundColor(.red)
                    Text(potentialOverdraw, format: .currency(code: "USD"))
                        .foregroundColor(.red)
                        .bold()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct BalanceCard: View {
    let title: String
    let amount: Double
    let backgroundColor: Color
    var textColor: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(amount, format: .currency(code: "USD"))
                .font(.title2)
                .bold()
                .foregroundColor(textColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HeaderView(balanceInfo: BalanceInfo(
        payTotal: 4000,
        actualRemaining: 2500,
        expenseTotalPaid: 1000,
        expenseTotalUnpaid: 500,
        balance: 2500,
        overdraw: 2000
    ))
    .modelContainer(for: [Expense.self, BalanceInfo.self], inMemory: true)
} 
