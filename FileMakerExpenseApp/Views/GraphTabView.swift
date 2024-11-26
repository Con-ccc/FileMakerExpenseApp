import SwiftUI
import Charts
import SwiftData

struct GraphTabView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    @State private var selectedGraphType: GraphType = .overview
    
    enum GraphType: String, CaseIterable {
        case overview = "Summary"
        case monthlyTrends = "Monthly"
        case categoryAnalysis = "Categories"
        case budgetStatus = "Budget"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Graph Type", selection: $selectedGraphType) {
                    ForEach(GraphType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedGraphType {
                        case .overview:
                            FinancialSummaryView(expenses: expenses, selectedPeriod: selectedPeriod)
                        case .monthlyTrends:
                            MonthlyTrendsView(expenses: expenses, selectedPeriod: selectedPeriod)
                        case .categoryAnalysis:
                            CategoryAnalysisView(expenses: expenses, selectedPeriod: selectedPeriod)
                        case .budgetStatus:
                            BudgetStatusView(expenses: expenses, selectedPeriod: selectedPeriod)
                        }
                    }
                }
            }
            .navigationTitle("Financial Analysis")
        }
    }
}

// Financial Summary View (Income vs Expenses Overview)
struct FinancialSummaryView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    @State private var selectedSegment: String? = nil
    
    enum Segment: String {
        case paidExpenses = "Paid Expenses"
        case unpaidExpenses = "Unpaid Expenses"
        case income = "Income"
    }
    
    private var summaryData: (income: Double, paidExpenses: Double, unpaidExpenses: Double, savings: Double) {
        let filteredExpenses = filterExpenses(expenses)
        let income = filteredExpenses
            .filter { $0.category == .income }
            .reduce(0) { $0 + $1.amount }
        let paidExpenses = filteredExpenses
            .filter { $0.category != .income && $0.isPaid }
            .reduce(0) { $0 + $1.amount }
        let unpaidExpenses = filteredExpenses
            .filter { $0.category != .income && !$0.isPaid }
            .reduce(0) { $0 + $1.amount }
        return (income, paidExpenses, unpaidExpenses, income - paidExpenses)
    }
    
    private var selectedTransactions: [Expense] {
        let filtered = filterExpenses(expenses)
        guard let segmentType = selectedSegment.flatMap(Segment.init) else { return [] }
        
        switch segmentType {
        case .paidExpenses:
            return filtered
                .filter { $0.category != .income && $0.isPaid }
                .sorted { $0.amount > $1.amount }
        case .unpaidExpenses:
            return filtered
                .filter { $0.category != .income && !$0.isPaid }
                .sorted { $0.amount > $1.amount }
        case .income:
            return filtered
                .filter { $0.category == .income }
                .sorted { $0.amount > $1.amount }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Donut chart with interactive buttons
            ZStack {
                Chart {
                    SectorMark(
                        angle: .value("Income", summaryData.income),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.green)
                    .opacity(selectedSegment == Segment.income.rawValue ? 1.0 : 0.7)
                    
                    SectorMark(
                        angle: .value("Paid Expenses", summaryData.paidExpenses),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.red)
                    .opacity(selectedSegment == Segment.paidExpenses.rawValue ? 1.0 : 0.7)
                    
                    SectorMark(
                        angle: .value("Unpaid Expenses", summaryData.unpaidExpenses),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(.orange)
                    .opacity(selectedSegment == Segment.unpaidExpenses.rawValue ? 1.0 : 0.7)
                }
                .frame(height: 200)
                
                // Add tap areas for interaction
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let radius = min(geometry.size.width, geometry.size.height) / 2
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let vector = CGPoint(
                                        x: value.location.x - center.x,
                                        y: value.location.y - center.y
                                    )
                                    
                                    // Calculate angle in degrees
                                    let angle = atan2(vector.y, vector.x) * 180 / .pi
                                    let normalizedAngle = (angle + 360).truncatingRemainder(dividingBy: 360)
                                    
                                    // Determine which segment was tapped
                                    let totalValue = summaryData.income + summaryData.paidExpenses + summaryData.unpaidExpenses
                                    let incomeAngle = (summaryData.income / totalValue) * 360
                                    let paidExpensesAngle = (summaryData.paidExpenses / totalValue) * 360
                                    
                                    var currentAngle: Double = 0
                                    if normalizedAngle < incomeAngle {
                                        withAnimation {
                                            selectedSegment = selectedSegment == Segment.income.rawValue ? nil : Segment.income.rawValue
                                        }
                                    } else {
                                        currentAngle += incomeAngle
                                        if normalizedAngle < currentAngle + paidExpensesAngle {
                                            withAnimation {
                                                selectedSegment = selectedSegment == Segment.paidExpenses.rawValue ? nil : Segment.paidExpenses.rawValue
                                            }
                                        } else {
                                            withAnimation {
                                                selectedSegment = selectedSegment == Segment.unpaidExpenses.rawValue ? nil : Segment.unpaidExpenses.rawValue
                                            }
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 200)
            
            // Summary statistics
            VStack(spacing: 12) {
                SummaryRow(title: "Total Income", amount: summaryData.income, color: .green)
                SummaryRow(title: "Paid Expenses", amount: summaryData.paidExpenses, color: .red)
                SummaryRow(title: "Unpaid Expenses", amount: summaryData.unpaidExpenses, color: .orange)
                SummaryRow(title: "Net Savings", amount: summaryData.savings, 
                          color: summaryData.savings >= 0 ? .green : .red)
                
                if summaryData.income > 0 {
                    Text("Savings Rate: \((summaryData.savings/summaryData.income * 100), specifier: "%.1f")%")
                        .font(.headline)
                        .foregroundColor(summaryData.savings >= 0 ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Selected segment details
            if !selectedTransactions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedSegment ?? "") Details")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(selectedTransactions) { transaction in
                        HStack {
                            Image(systemName: transaction.category.icon)
                                .foregroundColor(Color(transaction.category.color))
                            
                            VStack(alignment: .leading) {
                                Text(transaction.name)
                                    .font(.subheadline)
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(transaction.amount, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                if transaction.category != .income {
                                    Text(transaction.isPaid ? "Paid" : "Unpaid")
                                        .font(.caption)
                                        .foregroundColor(transaction.isPaid ? .green : .red)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

// Monthly Trends View (Month-by-month analysis)
struct MonthlyTrendsView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expenses: Double
        let savings: Double
    }
    
    private var monthlyData: [MonthlyData] {
        let calendar = Calendar.current
        let filteredExpenses = filterExpenses(expenses)
        
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfMonth(for: expense.date)
        }
        
        return grouped.map { date, expenses in
            let income = expenses
                .filter { $0.category == .income }
                .reduce(0) { $0 + $1.amount }
            let expenseTotal = expenses
                .filter { $0.category != .income }
                .reduce(0) { $0 + $1.amount }
            return MonthlyData(
                month: date,
                income: income,
                expenses: expenseTotal,
                savings: income - expenseTotal
            )
        }.sorted { $0.month < $1.month }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Chart {
                ForEach(monthlyData) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.income)
                    )
                    .foregroundStyle(.green)
                    .symbol(.circle)
                    
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.expenses)
                    )
                    .foregroundStyle(.red)
                    .symbol(.circle)
                    
                    AreaMark(
                        x: .value("Month", data.month),
                        y: .value("Savings", data.savings)
                    )
                    .foregroundStyle(.green.opacity(0.1))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month())
                }
            }
            
            // Monthly statistics
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(monthlyData) { data in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(data.month, format: .dateTime.month())
                                .font(.headline)
                            Text("Income: \(data.income, format: .currency(code: "USD"))")
                                .foregroundColor(.green)
                            Text("Expenses: \(data.expenses, format: .currency(code: "USD"))")
                                .foregroundColor(.red)
                            Text("Savings: \(data.savings, format: .currency(code: "USD"))")
                                .foregroundColor(data.savings >= 0 ? .green : .red)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

// Category Analysis View (Detailed category breakdown)
struct CategoryAnalysisView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    struct CategoryData: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let amount: Double
        let percentage: Double
        let count: Int
        let averageAmount: Double
    }
    
    private var categoryData: [CategoryData] {
        let filteredExpenses = filterExpenses(expenses)
            .filter { $0.category != .income }
        
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        
        return Dictionary(grouping: filteredExpenses) { $0.category }
            .map { category, expenses in
                let amount = expenses.reduce(0) { $0 + $1.amount }
                return CategoryData(
                    category: category,
                    amount: amount,
                    percentage: total > 0 ? (amount / total * 100) : 0,
                    count: expenses.count,
                    averageAmount: amount / Double(expenses.count)
                )
            }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Category distribution pie chart
            Chart(categoryData) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(item.category.color))
            }
            .frame(height: 200)
            
            // Category details
            ForEach(categoryData) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundColor(Color(item.category.color))
                        Text(item.category.rawValue)
                            .font(.headline)
                        Spacer()
                        Text(item.amount, format: .currency(code: "USD"))
                    }
                    
                    HStack {
                        Text("\(item.percentage, specifier: "%.1f")% of total")
                        Spacer()
                        Text("\(item.count) transactions")
                        Spacer()
                        Text("Avg: \(item.averageAmount, format: .currency(code: "USD"))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

// Budget Status View (Progress towards budget goals)
struct BudgetStatusView: View {
    let expenses: [Expense]
    let selectedPeriod: TimePeriod
    
    // Example budget limits (you might want to make these configurable)
    private let budgetLimits: [ExpenseCategory: Double] = [
        .rent: 2000,
        .utilities: 300,
        .groceries: 600,
        .transportation: 400,
        .entertainment: 300,
        .healthcare: 200,
        .other: 500
    ]
    
    struct BudgetData: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let spent: Double
        let limit: Double
        var percentage: Double { (spent / limit) * 100 }
        var remaining: Double { limit - spent }
    }
    
    private var budgetData: [BudgetData] {
        let filteredExpenses = filterExpenses(expenses)
        
        return budgetLimits.map { category, limit in
            let spent = filteredExpenses
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            return BudgetData(
                category: category,
                spent: spent,
                limit: limit
            )
        }
        .sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(budgetData) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundColor(Color(item.category.color))
                        Text(item.category.rawValue)
                        Spacer()
                        Text(item.spent, format: .currency(code: "USD"))
                        Text("of")
                        Text(item.limit, format: .currency(code: "USD"))
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(item.percentage > 100 ? Color.red : Color(item.category.color))
                                .frame(width: min(CGFloat(item.percentage) * geometry.size.width / 100, geometry.size.width))
                                .frame(height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("\(item.percentage, specifier: "%.1f")%")
                        Spacer()
                        Text("Remaining: \(item.remaining, format: .currency(code: "USD"))")
                            .foregroundColor(item.remaining >= 0 ? .green : .red)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let dateRange = selectedPeriod.dateRange()
        return expenses.filter { expense in
            (expense.date >= dateRange.start) && (expense.date <= dateRange.end)
        }
    }
}

struct SummaryRow: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(amount, format: .currency(code: "USD"))
                .foregroundColor(color)
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    GraphTabView(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, isPaid: true, category: .rent),
            Expense(name: "Groceries", amount: 500, isPaid: false, category: .groceries)
        ],
        selectedPeriod: .thisMonth
    )
} 