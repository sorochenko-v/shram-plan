import SwiftUI

extension Color {
    static let scarlet = Color(red: 0.65, green: 0.08, blue: 0.14)
    static let forest = Color(red: 0.05, green: 0.35, blue: 0.20)
    static let matteGold = Color(red: 0.88, green: 0.62, blue: 0.05)
}

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("showPostLoginPaywall") var showPostLoginPaywall: Bool = false
    @AppStorage("isProUser") var isProUser: Bool = false
    @State private var selectedTab = 0
    @State private var showSubscriptionPaywall = false

    var body: some View {
        Group {
            if isLoggedIn {
                VStack(spacing: 0) {
                    MainTabView(
                        selectedTab: $selectedTab,
                        showSubscriptionPaywall: $showSubscriptionPaywall
                    )
                }
                .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            } else {
                LoginView()
            }
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
        }
        .onChange(of: showPostLoginPaywall) { _, newValue in
            if newValue {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    showSubscriptionPaywall = true
                    showPostLoginPaywall = false
                }
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var showSubscriptionPaywall: Bool

    @AppStorage("avatarIcon") var avatarIcon: String = "person.crop.circle.fill"
    @AppStorage("customAvatarData") var customAvatarData: Data = Data()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HabitsView()
            }
            .tabItem {
                Label("Habits", systemImage: "checklist")
            }
            .tag(0)

            NavigationStack {
                FinanceView()
            }
            .tabItem {
                Label("Finance", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(1)

            NavigationStack {
                PlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: "calendar")
            }
            .tag(2)

            ProfileTabView()
                .tabItem {
                    Label {
                        Text("Profile")
                    } icon: {
                        AvatarView(iconName: avatarIcon, customData: customAvatarData, size: 22)
                    }
                }
                .tag(3)
        }
        .tint(.scarlet)
    }
}


