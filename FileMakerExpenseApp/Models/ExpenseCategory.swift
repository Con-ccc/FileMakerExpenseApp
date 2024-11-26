import Foundation

enum ExpenseCategory: String, CaseIterable, Codable {
    // Income category
    case income = "Income"
    
    // Expense categories
    case rent = "Rent"
    case utilities = "Utilities"
    case groceries = "Groceries"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case healthcare = "Healthcare"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .income: return "dollarsign.circle.fill"
        case .rent: return "house.fill"
        case .utilities: return "bolt.fill"
        case .groceries: return "cart.fill"
        case .transportation: return "car.fill"
        case .entertainment: return "tv.fill"
        case .healthcare: return "cross.case.fill"
        case .other: return "square.fill"
        }
    }
    
    var color: String {
        switch self {
        case .income: return "green"
        case .rent: return "blue"
        case .utilities: return "yellow"
        case .groceries: return "orange"
        case .transportation: return "purple"
        case .entertainment: return "pink"
        case .healthcare: return "red"
        case .other: return "gray"
        }
    }
    
    // Helper to determine if this is an expense category
    var isExpense: Bool {
        self != .income
    }
    
    // Get only expense categories
    static var expenseCategories: [ExpenseCategory] {
        Self.allCases.filter { $0.isExpense }
    }
    
    // Get only income category
    static var incomeCategories: [ExpenseCategory] {
        Self.allCases.filter { !$0.isExpense }
    }
} 
