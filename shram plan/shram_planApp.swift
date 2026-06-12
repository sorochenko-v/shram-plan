import SwiftUI

@main
struct shram_planApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            // Додали Group, щоб Xcode чітко розумів логіку перемикання екранів
            Group {
                if isLoggedIn {
                    ContentView()
                } else {
                    LoginView()
                }
            }
        }
    }
}
