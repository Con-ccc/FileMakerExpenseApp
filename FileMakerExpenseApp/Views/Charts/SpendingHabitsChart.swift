import SwiftUI
import Charts

struct SpendingHabitsChart: View {
    let expenses: [Expense]
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var isAnimating: Bool
    
    struct CategorySpending: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let totalAmount: Double
        let paidAmount: Double
        let unpaidAmount: Double
        let transactionCount: Int
        let percentage: Double
    }
    
    private var categoryData: [CategorySpending] {
        let expensesByCategory = Dictionary(grouping: expenses.filter { $0.category != .income }) {
            $0.category
        }
        
        let totalSpending = expenses
            .filter { $0.category != .income }
            .reduce(0) { $0 + $1.amount }
        
        return expensesByCategory.map { category, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            let paid = expenses.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
            let unpaid = expenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
            
            return CategorySpending(
                category: category,
                totalAmount: total,
                paidAmount: paid,
                unpaidAmount: unpaid,
                transactionCount: expenses.count,
                percentage: (total / totalSpending) * 100
            )
        }
        .sorted { $0.totalAmount > $1.totalAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Habits Analysis")
                .font(.headline)
            
            // Animated Pie Chart with tap gesture
            ZStack {
                Chart {
                    ForEach(categoryData) { category in
                        SectorMark(
                            angle: .value("Amount", isAnimating ? category.totalAmount : 0),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color(category.category.color))
                        .opacity(selectedCategory == category.category ? 1.0 : 0.7)
                    }
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
                                    
                                    // Find the category at this angle
                                    var currentAngle: Double = 0
                                    let total = categoryData.reduce(0) { $0 + $1.totalAmount }
                                    
                                    for categorySpending in categoryData {
                                        let sectorAngle = (categorySpending.totalAmount / total) * 360
                                        if normalizedAngle < currentAngle + sectorAngle {
                                            withAnimation {
                                                selectedCategory = selectedCategory == categorySpending.category ? nil : categorySpending.category
                                            }
                                            break
                                        }
                                        currentAngle += sectorAngle
                                    }
                                }
                        )
                }
            }
            .frame(height: 200)
            
            // Category Legend with Interactive Selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categoryData) { category in
                        Button {
                            withAnimation {
                                selectedCategory = selectedCategory == category.category ? nil : category.category
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(category.category.color))
                                    .frame(width: 10, height: 10)
                                Text(category.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedCategory == category.category ?
                                         Color(category.category.color).opacity(0.2) :
                                            Color.gray.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Category Details
            if let selected = selectedCategory,
               let categoryInfo = categoryData.first(where: { $0.category == selected }) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: selected.icon)
                            .foregroundColor(Color(selected.color))
                        Text(selected.rawValue)
                            .font(.headline)
                        Spacer()
                        Text(categoryInfo.totalAmount, format: .currency(code: "USD"))
                            .bold()
                    }
                    
                    // Progress bars for paid/unpaid
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(
                            "Paid",
                            value: categoryInfo.paidAmount,
                            total: categoryInfo.totalAmount
                        )
                        .tint(.green)
                        
                        ProgressView(
                            "Unpaid",
                            value: categoryInfo.unpaidAmount,
                            total: categoryInfo.totalAmount
                        )
                        .tint(.red)
                    }
                    
                    // Statistics
                    HStack {
                        StatisticView(
                            title: "Transactions",
                            value: "\(categoryInfo.transactionCount)"
                        )
                        
                        StatisticView(
                            title: "Of Total",
                            value: String(format: "%.1f%%", categoryInfo.percentage)
                        )
                        
                        StatisticView(
                            title: "Avg Amount",
                            value: (categoryInfo.totalAmount / Double(categoryInfo.transactionCount))
                                .formatted(.currency(code: "USD"))
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
        .padding()
        .animation(.spring(), value: selectedCategory)
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SpendingHabitsChart(
        expenses: [
            Expense(name: "Rent", amount: 1500, isPaid: true, category: .rent),
            Expense(name: "Groceries", amount: 500, isPaid: false, category: .groceries),
            Expense(name: "Internet", amount: 80, isPaid: true, category: .utilities)
        ],
        selectedCategory: .constant(nil),
        isAnimating: .constant(true)
    )
} 