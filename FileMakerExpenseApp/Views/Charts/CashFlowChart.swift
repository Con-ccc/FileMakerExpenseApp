import SwiftUI
import Charts

struct CashFlowChart: View {
    let expenses: [Expense]
    @Binding var isAnimating: Bool
    
    struct DailyFlow: Identifiable {
        let id = UUID()
        let date: Date
        let income: Double
        let expenses: Double
        let netFlow: Double
        
        var formattedDate: String {
            date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private var dailyData: [DailyFlow] {
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        return groupedByDate.map { date, transactions in
            let income = transactions
                .filter { $0.category == .income }
                .reduce(0) { $0 + $1.amount }
            let expenses = transactions
                .filter { $0.category != .income }
                .reduce(0) { $0 + $1.amount }
            return DailyFlow(
                date: date,
                income: income,
                expenses: expenses,
                netFlow: income - expenses
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cash Flow Analysis")
                .font(.headline)
            
            Chart {
                ForEach(dailyData) { flow in
                    LineMark(
                        x: .value("Date", flow.date),
                        y: .value("Income", isAnimating ? flow.income : 0)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", flow.date),
                        y: .value("Expenses", isAnimating ? flow.expenses : 0)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", flow.date),
                        y: .value("Net Flow", isAnimating ? flow.netFlow : 0)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
            
            // Summary Cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FlowSummaryCard(
                    title: "Total Income",
                    amount: dailyData.reduce(0) { $0 + $1.income },
                    color: .green
                )
                
                FlowSummaryCard(
                    title: "Total Expenses",
                    amount: dailyData.reduce(0) { $0 + $1.expenses },
                    color: .red
                )
                
                FlowSummaryCard(
                    title: "Net Flow",
                    amount: dailyData.reduce(0) { $0 + $1.netFlow },
                    color: .blue
                )
            }
            
            // Daily Breakdown
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(dailyData) { flow in
                        HStack {
                            Text(flow.formattedDate)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if flow.income > 0 {
                                    Text("+ \(flow.income, format: .currency(code: "USD"))")
                                        .foregroundColor(.green)
                                }
                                if flow.expenses > 0 {
                                    Text("- \(flow.expenses, format: .currency(code: "USD"))")
                                        .foregroundColor(.red)
                                }
                                Text("= \(flow.netFlow, format: .currency(code: "USD"))")
                                    .foregroundColor(flow.netFlow >= 0 ? .blue : .red)
                                    .bold()
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .animation(.spring(), value: isAnimating)
    }
}

struct FlowSummaryCard: View {
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
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    CashFlowChart(
        expenses: [
            Expense(name: "Salary", amount: 5000, category: .income),
            Expense(name: "Rent", amount: 1500, isPaid: true, category: .rent),
            Expense(name: "Groceries", amount: 500, isPaid: false, category: .groceries)
        ],
        isAnimating: .constant(true)
    )
} 