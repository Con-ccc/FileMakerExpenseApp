import SwiftUI
import SwiftData

@main
struct FileMakerExpenseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Expense.self, BalanceInfo.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
} 