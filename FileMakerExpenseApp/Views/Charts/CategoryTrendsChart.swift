import SwiftUI
import Charts

struct CategoryTrendsChart: View {
    let expenses: [Expense]
    @Binding var isAnimating: Bool
    
    struct CategoryTrend: Identifiable {
        let id = UUID()
        let date: Date
        let category: ExpenseCategory
        let amount: Double
    }
    
    private var trendData: [CategoryTrend] {
        let calendar = Calendar.current
        let expensesByDate = Dictionary(grouping: expenses.filter { $0.category != .income }) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        var trends: [CategoryTrend] = []
        
        for (date, dayExpenses) in expensesByDate {
            let categoryAmounts = Dictionary(grouping: dayExpenses) { $0.category }
            
            for (category, expenses) in categoryAmounts {
                let totalAmount = expenses.reduce(0) { $0 + $1.amount }
                trends.append(CategoryTrend(
                    date: date,
                    category: category,
                    amount: totalAmount
                ))
            }
        }
        
        return trends.sorted { $0.date < $1.date }
    }
    
    private var categories: [ExpenseCategory] {
        Array(Set(trendData.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Trends")
                .font(.headline)
            
            // Stacked Area Chart
            Chart {
                ForEach(categories, id: \.self) { category in
                    ForEach(trendData.filter { $0.category == category }) { trend in
                        AreaMark(
                            x: .value("Date", trend.date),
                            y: .value("Amount", isAnimating ? trend.amount : 0)
                        )
                        .foregroundStyle(Color(category.color))
                        .opacity(0.7)
                    }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            
            // Category Legend
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(Color(category.color))
                            .frame(width: 10, height: 10)
                        Text(category.rawValue)
                            .font(.caption)
                        Spacer()
                        Text(totalForCategory(category), format: .currency(code: "USD"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(category.color).opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Daily Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Breakdown")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(Dictionary(grouping: trendData) { $0.date }
                            .sorted { $0.key > $1.key }), id: \.key) { date, trends in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(trends.sorted { $0.amount > $1.amount }) { trend in
                                    HStack {
                                        Image(systemName: trend.category.icon)
                                            .foregroundColor(Color(trend.category.color))
                                        Text(trend.category.rawValue)
                                            .font(.caption)
                                        Spacer()
                                        Text(trend.amount, format: .currency(code: "USD"))
                                            .font(.caption)
                                    }
                                }
                                
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .animation(.spring(), value: isAnimating)
    }
    
    private func totalForCategory(_ category: ExpenseCategory) -> Double {
        trendData
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
}

#Preview {
    CategoryTrendsChart(
        expenses: [
            Expense(name: "Rent", amount: 1500, category: .rent),
            Expense(name: "Groceries", amount: 200, category: .groceries),
            Expense(name: "Internet", amount: 80, category: .utilities)
        ],
        isAnimating: .constant(true)
    )
} 