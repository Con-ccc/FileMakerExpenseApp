import SwiftUI
import SwiftData

struct CalendarView: View {
    let expenses: [Expense]
    @State private var selectedDate = Date()
    @State private var showingAddExpense = false
    
    private var expensesForSelectedDate: [Expense] {
        expenses.filter { expense in
            Calendar.current.isDate(expense.date, inSameDayAs: selectedDate)
        }
    }
    
    private var totalForSelectedDate: Double {
        expensesForSelectedDate
            .filter { $0.category != .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var incomeForSelectedDate: Double {
        expensesForSelectedDate
            .filter { $0.category == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Calendar
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                // Daily Summary
                VStack(spacing: 16) {
                    HStack {
                        if incomeForSelectedDate > 0 {
                            DailySummaryCard(
                                title: "Income",
                                amount: incomeForSelectedDate,
                                icon: "arrow.down.circle.fill",
                                color: .green
                            )
                        }
                        
                        if totalForSelectedDate > 0 {
                            DailySummaryCard(
                                title: "Expenses",
                                amount: totalForSelectedDate,
                                icon: "arrow.up.circle.fill",
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Transactions List
                List {
                    ForEach(expensesForSelectedDate) { expense in
                        ExpenseRowView(expense: expense)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Calendar")
            .toolbar {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }
}

struct DailySummaryCard: View {
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

#Preview {
    CalendarView(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, category: .rent),
            Expense(name: "Groceries", amount: 500, category: .groceries)
        ]
    )
} 