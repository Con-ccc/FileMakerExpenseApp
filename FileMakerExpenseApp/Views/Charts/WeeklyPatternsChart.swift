import SwiftUI
import Charts

// Move HourlySpending struct outside of WeeklyPatternsChart
struct HourlySpending: Identifiable {
    let id = UUID()
    let weekday: Int
    let hour: Int
    let amount: Double
    let count: Int
    
    var weekdayName: String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }
    
    var timeString: String {
        String(format: "%02d:00", hour)
    }
}

struct WeeklyPatternsChart: View {
    let expenses: [Expense]
    @Binding var isAnimating: Bool
    
    // MARK: - Data Processing
    private func processExpenseData() -> [HourlySpending] {
        let calendar = Calendar.current
        var result: [HourlySpending] = []
        
        // Group expenses by weekday and hour
        var spendingByTime: [String: (amount: Double, count: Int)] = [:]
        
        // Process each expense
        for expense in expenses where expense.category != .income {
            let weekday = calendar.component(.weekday, from: expense.date)
            let hour = calendar.component(.hour, from: expense.date)
            let key = "\(weekday)-\(hour)"
            
            let current = spendingByTime[key] ?? (0, 0)
            spendingByTime[key] = (
                current.amount + expense.amount,
                current.count + 1
            )
        }
        
        // Convert to HourlySpending objects
        for (key, value) in spendingByTime {
            let components = key.split(separator: "-").map { Int($0)! }
            let spending = HourlySpending(
                weekday: components[0],
                hour: components[1],
                amount: value.amount,
                count: value.count
            )
            result.append(spending)
        }
        
        return result
    }
    
    private var hourlyData: [HourlySpending] {
        processExpenseData()
    }
    
    private var maxAmount: Double {
        hourlyData.map { $0.amount }.max() ?? 0
    }
    
    private func colorForAmount(_ amount: Double) -> Color {
        if amount == 0 {
            return .gray.opacity(0.1)
        }
        let intensity = amount / maxAmount
        return .blue.opacity(0.1 + (intensity * 0.9))
    }
    
    // MARK: - View Components
    private func WeekdayRow(weekday: Int) -> some View {
        HStack(spacing: 4) {
            Text(Calendar.current.weekdaySymbols[weekday - 1])
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            
            ForEach(0..<24) { hour in
                let spending = hourlyData.first {
                    $0.weekday == weekday && $0.hour == hour
                }
                
                HourCell(spending: spending)
            }
        }
    }
    
    private func HourCell(spending: HourlySpending?) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(colorForAmount(spending?.amount ?? 0))
            .frame(height: 20)
            .overlay(
                Text(spending != nil ? "💰" : "")
                    .font(.caption2)
                    .opacity(isAnimating ? 1 : 0)
            )
            .onTapGesture {
                if let spending = spending {
                    showSpendingDetails(spending)
                }
            }
    }
    
    // MARK: - Main View
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Spending Patterns")
                .font(.headline)
            
            // Heatmap
            VStack(alignment: .leading, spacing: 4) {
                ForEach(1...7, id: \.self) { weekday in
                    WeekdayRow(weekday: weekday)
                }
            }
            
            // Time scale
            TimeScaleView()
            
            // Legend
            SpendingLegendView(maxAmount: maxAmount)
            
            // Popular spending times
            PopularTimesView(hourlyData: hourlyData)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .animation(.spring(), value: isAnimating)
    }
    
    private func showSpendingDetails(_ spending: HourlySpending) {
        print("Spending at \(spending.weekdayName) \(spending.timeString): \(spending.amount)")
    }
}

// MARK: - Supporting Views
private struct TimeScaleView: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Hour:")
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            
            ForEach(Array(stride(from: 0, to: 24, by: 6)), id: \.self) { hour in
                Text("\(hour)")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct SpendingLegendView: View {
    let maxAmount: Double
    
    var body: some View {
        HStack {
            Text("Spending Intensity:")
                .font(.caption)
            
            ForEach([0.0, maxAmount * 0.25, maxAmount * 0.5, maxAmount * 0.75, maxAmount], id: \.self) { value in
                RoundedRectangle(cornerRadius: 4)
                    .fill(value == 0 ? .gray.opacity(0.1) : .blue.opacity(0.1 + (value/maxAmount * 0.9)))
                    .frame(width: 20, height: 20)
                
                Text(value, format: .currency(code: "USD"))
                    .font(.caption)
            }
        }
        .padding(.top)
    }
}

private struct PopularTimesView: View {
    let hourlyData: [HourlySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular Spending Times")
                .font(.headline)
            
            let topTimes = hourlyData
                .sorted { $0.amount > $1.amount }
                .prefix(5)
            
            ForEach(Array(topTimes)) { spending in
                HStack {
                    Text("\(spending.weekdayName) at \(spending.timeString)")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(spending.amount, format: .currency(code: "USD"))
                            .bold()
                        Text("\(spending.count) transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }
} 