import SwiftUI
import Charts

// Move types outside of the view
struct BudgetProgress: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let spent: Double
    let budget: Double
    let transactions: Int
    
    var percentUsed: Double {
        (spent / budget) * 100
    }
    
    var remaining: Double {
        budget - spent
    }
    
    var status: BudgetStatus {
        if percentUsed >= 100 {
            return .overBudget
        } else if percentUsed >= 80 {
            return .warning
        } else {
            return .good
        }
    }
}

enum BudgetStatus {
    case good, warning, overBudget
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .overBudget: return .red
        }
    }
}

struct BudgetAndGoalsView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    // Example budget targets
    private let monthlyBudgets: [ExpenseCategory: Double] = [
        .rent: 2000,
        .utilities: 300,
        .groceries: 600,
        .transportation: 400,
        .entertainment: 300,
        .healthcare: 200,
        .other: 500
    ]
    
    private var budgetProgress: [BudgetProgress] {
        let filteredExpenses = filterExpenses(expenses)
        
        return monthlyBudgets.map { category, budget in
            let categoryExpenses = filteredExpenses.filter { $0.category == category }
            let spent = categoryExpenses.reduce(0) { $0 + $1.amount }
            
            return BudgetProgress(
                category: category,
                spent: spent,
                budget: budget,
                transactions: categoryExpenses.count
            )
        }
        .sorted { $0.percentUsed > $1.percentUsed }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Budget Summary
                    BudgetSummaryCard(budgetProgress: budgetProgress)
                    
                    // Category Progress
                    ForEach(budgetProgress) { progress in
                        BudgetProgressCard(progress: progress)
                    }
                }
                .padding()
            }
            .navigationTitle("Budget Tracker")
        }
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

struct BudgetSummaryCard: View {
    let budgetProgress: [BudgetProgress]
    
    private var totalBudget: Double {
        budgetProgress.reduce(0) { $0 + $1.budget }
    }
    
    private var totalSpent: Double {
        budgetProgress.reduce(0) { $0 + $1.spent }
    }
    
    private var overBudgetCategories: Int {
        budgetProgress.filter { $0.status == .overBudget }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Overall progress
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Budget")
                        .font(.headline)
                    Text(totalBudget, format: .currency(code: "USD"))
                        .font(.title2)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Spent")
                        .font(.headline)
                    Text(totalSpent, format: .currency(code: "USD"))
                        .font(.title2)
                        .bold()
                        .foregroundColor(totalSpent > totalBudget ? .red : .green)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(totalSpent > totalBudget ? Color.red : Color.green)
                        .frame(width: min(CGFloat(totalSpent / totalBudget) * geometry.size.width, geometry.size.width))
                        .frame(height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Alerts
            if overBudgetCategories > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("\(overBudgetCategories) categories over budget")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct BudgetProgressCard: View {
    let progress: BudgetProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: progress.category.icon)
                    .foregroundColor(Color(progress.category.color))
                Text(progress.category.rawValue)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(progress.spent, format: .currency(code: "USD"))
                    Text("of")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(progress.budget, format: .currency(code: "USD"))
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progress.status.color)
                        .frame(width: min(CGFloat(progress.percentUsed) * geometry.size.width / 100, geometry.size.width))
                        .frame(height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(progress.percentUsed, specifier: "%.1f")%")
                Spacer()
                Text("\(progress.transactions) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Remaining: \(progress.remaining, format: .currency(code: "USD"))")
                    .foregroundColor(progress.status.color)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    BudgetAndGoalsView(
        expenses: [
            Expense(name: "Rent", amount: 1500, category: .rent),
            Expense(name: "Groceries", amount: 400, category: .groceries),
            Expense(name: "Internet", amount: 80, category: .utilities)
        ],
        selectedPeriod: .thisMonth
    )
} 