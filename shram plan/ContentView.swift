import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("showPostLoginPaywall") var showPostLoginPaywall: Bool = false
    @AppStorage("isProUser") var isProUser: Bool = false
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var showSubscriptionPaywall = false
    @State private var showHabitAddModal = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView(
                    selectedTab: $selectedTab,
                    showProfile: $showProfile,
                    showSubscriptionPaywall: $showSubscriptionPaywall,
                    showHabitAddModal: $showHabitAddModal
                )
            } else {
                LoginView()
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileModalView(showProfile: $showProfile)
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
        }
        .sheet(isPresented: $showHabitAddModal) {
            NavigationStack {
                HabitsView(showAddModal: $showHabitAddModal)
            }
        }
        .onChange(of: showPostLoginPaywall) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSubscriptionPaywall = true
                    showPostLoginPaywall = false
                }
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var showProfile: Bool
    @Binding var showSubscriptionPaywall: Bool
    @Binding var showHabitAddModal: Bool

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: "calendar")
            }
            .tag(0)

            NavigationStack {
                HabitsView(showAddModal: $showHabitAddModal)
            }
            .tabItem {
                Label("Habits", systemImage: "repeat")
            }
            .tag(1)

            NavigationStack {
                FinanceView()
            }
            .tabItem {
                Label("Finance", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)

            NavigationStack {
                SettingsView(showProfile: $showProfile, showSubscriptionPaywall: $showSubscriptionPaywall)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
        .tint(.blue)
    }
}

struct SettingsView: View {
    @Binding var showProfile: Bool
    @Binding var showSubscriptionPaywall: Bool
    @AppStorage("isProUser") var isProUser: Bool = false

    var body: some View {
        List {
            Section {
                Button {
                    showProfile = true
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Profile")
                                .font(.headline)
                            Text("Manage your account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Subscription") {
                HStack {
                    Image(systemName: isProUser ? "crown.fill" : "crown")
                        .font(.title2)
                        .foregroundColor(isProUser ? .yellow : .gray)
                    VStack(alignment: .leading) {
                        Text(isProUser ? "Pro Active" : "Free Tier")
                            .font(.headline)
                        Text(isProUser ? "All features unlocked" : "Upgrade for unlimited access")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if !isProUser {
                        Button("Upgrade") {
                            showSubscriptionPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            Section("About") {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Shram Plan")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    // Logout logic would go here
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct ProfileModalView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userName") var userName: String = "Your Name"
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"
    @AppStorage("avatarIcon") var avatarIcon: String = "person.crop.circle.fill"
    @AppStorage("customAvatarData") var customAvatarData: Data = Data()

    @Binding var showProfile: Bool

    @State private var showImagePicker = false
    @State private var showSubscriptionPaywall = false
    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        AvatarView(iconName: avatarIcon, customData: customAvatarData, size: 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    Button("Change Avatar") {
                        showImagePicker = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Personal Information") {
                    if isEditing {
                        TextField("Name", text: $editedName)
                        TextField("Email", text: $editedEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } else {
                        LabeledContent("Name", value: userName)
                        LabeledContent("Email", value: userEmail)
                    }
                }

                Section {
                    if isEditing {
                        Button("Save") {
                            userName = editedName
                            userEmail = editedEmail
                            isEditing = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        Button("Cancel") {
                            editedName = userName
                            editedEmail = userEmail
                            isEditing = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Button("Edit Profile") {
                            editedName = userName
                            editedEmail = userEmail
                            isEditing = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Section("Subscription") {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Pro Status")
                        Spacer()
                        Text("Active")
                            .foregroundColor(.green)
                    }
                    Button("Manage Subscription") {
                        showSubscriptionPaywall = true
                        showProfile = false
                    }
                }

                Section {
                    Button(role: .destructive) {
                        isLoggedIn = false
                        showProfile = false
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showProfile = false }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImageData: $customAvatarData, selectedIcon: $avatarIcon)
            }
            .sheet(isPresented: $showSubscriptionPaywall) {
                SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
            }
        }
    }
}

struct ChangeEmailView: View {
    @Binding var showSheet: Bool
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"
    @AppStorage("userPassword") var userPassword: String = "password123"

    @State private var newEmail = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Email") {
                    TextField("Enter new email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Confirm Password") {
                    SecureField("Current password", text: $confirmPassword)
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Update Email") {
                        if confirmPassword == userPassword {
                            userEmail = newEmail
                            showSheet = false
                        } else {
                            errorMessage = "Incorrect password"
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(newEmail.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSheet = false }
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Binding var showSheet: Bool
    @AppStorage("userPassword") var userPassword: String = "password123"
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"

    @State private var currentPasswordInput = ""
    @State private var newPasswordInput = ""
    @State private var errorMessage = ""
    @State private var showForgotAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    SecureField("Enter current password", text: $currentPasswordInput)
                }

                Section("New Password") {
                    SecureField("Enter new password", text: $newPasswordInput)
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Update Password") {
                        if currentPasswordInput == userPassword {
                            userPassword = newPasswordInput
                            showSheet = false
                        } else {
                            errorMessage = "Incorrect current password"
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(currentPasswordInput.isEmpty || newPasswordInput.isEmpty)
                }

                Section {
                    Button("Forgot Password?") {
                        showForgotAlert = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSheet = false }
                }
            }
            .alert("Password Reset", isPresented: $showForgotAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Password reset functionality would be implemented here with your backend service.")
            }
        }
    }
}

struct SubscriptionPaywallView: View {
    @Binding var isPresented: Bool
    @State private var selectedPlan: SubscriptionBillingPlan = .yearly
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .scaleEffect(pulse ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

                        Text("Unlock Shram Plan Pro")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text("Get unlimited access to all features and take your productivity to the next level.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    .onAppear { pulse = true }

                    VStack(spacing: 16) {
                        ForEach(SubscriptionBillingPlan.allCases) { plan in
                            PlanCard(plan: plan, isSelected: selectedPlan == plan) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPlan = plan
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Button {
                        // Purchase logic would go here
                        isPresented = false
                    } label: {
                        Text("Continue with \(selectedPlan.displayName)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Text("Cancel anytime. No ads. Full privacy.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Restore Purchases") {
                        // Restore logic
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
}

enum SubscriptionBillingPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: return "Monthly - $4.99/month"
        case .yearly: return "Yearly - $29.99/year (Save 50%)"
        case .lifetime: return "Lifetime - $99.99 (One-time)"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$29.99"
        case .lifetime: return "$99.99"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "month"
        case .yearly: return "year"
        case .lifetime: return "lifetime"
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionBillingPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.rawValue.capitalized)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(plan.price + " / " + plan.period)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AvatarView: View {
    var iconName: String
    var customData: Data
    var size: CGFloat

    var body: some View {
        Group {
            if !customData.isEmpty {
                #if os(macOS)
                if let nsImage = NSImage(data: customData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.blue)
                        .frame(width: size, height: size)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                #else
                if let uiImage = UIImage(data: customData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.blue)
                        .frame(width: size, height: size)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                #endif
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.blue)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }
        }
    }
}

struct ImagePicker: View {
    @Binding var selectedImageData: Data
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Avatar Selection")
                    .font(.headline)
                    .padding()

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        ForEach(avatarIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                selectedImageData = Data()
                                dismiss()
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 70, height: 70)
                                    .background(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                Button("Remove Custom Photo") {
                    selectedImageData = Data()
                    selectedIcon = "person.crop.circle.fill"
                    dismiss()
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private let avatarIcons = [
    "person.crop.circle.fill", "heart.fill", "star.fill", "bolt.fill",
    "leaf.fill", "flame.fill", "diamond.fill", "crown.fill",
    "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
    "gamecontroller.fill", "paintbrush.fill", "camera.fill", "music.note"
]
