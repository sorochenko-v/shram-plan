import SwiftUI
import PhotosUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @AppStorage("showPostLoginPaywall") var showPostLoginPaywall: Bool = false
    @AppStorage("isProUser") var isProUser: Bool = false
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var showSubscriptionPaywall = false
    @State private var showHabitAddModal = false

    @AppStorage("avatarIcon") var avatarIcon: String = "person.crop.circle.fill"
    @AppStorage("customAvatarData") var customAvatarData: Data = Data()

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mainHeader

                TabView(selection: $selectedTab) {
                    HabitsView(showAddModal: $showHabitAddModal)
                        .tag(0)
                        .tabItem {
                            Label(t("Habits", "Звички"), systemImage: "checkmark.circle")
                        }

                    FinanceView()
                        .tag(1)
                        .tabItem {
                            Label(t("Finance", "Фінанси"), systemImage: "dollarsign.circle")
                        }

                    PlannerView()
                        .tag(2)
                        .tabItem {
                            Label(t("Planner", "Планувальник"), systemImage: "calendar")
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "bandage.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(.systemBackground)))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)

                        HStack(spacing: 0) {
                            Text("Shram")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Plan")
                                .font(.system(size: 22, weight: .light, design: .rounded))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.leading, 4)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if !isProUser {
                            Button(action: { showSubscriptionPaywall = true }) {
                                HStack(spacing: 6) {
                                    Text("👑")
                                        .font(.system(size: 12))
                                    Text("PRO")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.orange.opacity(0.12)))
                                .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                            .accessibilityLabel(t("Open ShramPlan PRO", "Відкрити ShramPlan PRO"))
                        }

                        Button(action: {
                            showProfile = true
                        }) {
                            AvatarView(iconName: avatarIcon, customData: customAvatarData, size: 28)
                                .padding(5)
                                .background(Circle().fill(Color(.systemBackground)))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(t("Open Profile", "Відкрити профіль"))
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileModalView(showProfile: $showProfile)
            }
            .fullScreenCover(isPresented: $showSubscriptionPaywall) {
                SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
            }
            .onAppear {
                if showPostLoginPaywall {
                    showSubscriptionPaywall = true
                    showPostLoginPaywall = false
                }
            }
        }
    }

    private var mainHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHRAMPLAN")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.blue.opacity(0.8))
                .tracking(2)

            HStack(spacing: 10) {
                Text(currentTabTitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                if selectedTab == 0 {
                    Button(action: { showHabitAddModal = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.blue))
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t("Add Plan", "Додати план"))
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: selectedTab)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isProUser)
    }

    private var currentTabTitle: String {
        switch selectedTab {
        case 1:
            return t("Finance", "Фінанси")
        case 2:
            return t("Planner", "Планувальник")
        default:
            return t("Habits", "Звички")
        }
    }
}

// --- ПРЕМІУМНЕ ВІКНО ПРОФІЛЮ ---
struct ProfileModalView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @AppStorage("userName") var userName: String = "Your Name"
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"
    @AppStorage("avatarIcon") var avatarIcon: String = "person.crop.circle.fill"
    @AppStorage("customAvatarData") var customAvatarData: Data = Data()

    @Binding var showProfile: Bool

    @State private var showPasswordSheet = false
    @State private var showEmailSheet = false
    @State private var showSubscriptionPaywall = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    let availableAvatars = ["person.crop.circle.fill", "person.circle.fill", "sparkles", "bolt.shield.fill", "star.circle.fill", "flame.fill", "crown.fill"]

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Зона Аватарки
                    VStack(spacing: 12) {
                        AvatarView(iconName: avatarIcon, customData: customAvatarData, size: 95)
                            .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 3))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                        Menu {
                            Button(action: {
                                customAvatarData = Data()
                                if let currentIndex = availableAvatars.firstIndex(of: avatarIcon) {
                                    let nextIndex = (currentIndex + 1) % availableAvatars.count
                                    avatarIcon = availableAvatars[nextIndex]
                                }
                            }) {
                                Label(t("Choose Default Icon", "Обрати стандартну іконку"), systemImage: "person.circle")
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label(t("From Gallery", "З галереї"), systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                Text(t("Change Avatar", "Змінити аватар"))
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 14)
                            .padding(.top, 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 10)

                    // Картка статусу акаунта
                    VStack(alignment: .leading, spacing: 10) {
                        Text(t("ACCOUNT STATUS", "СТАТУС АКАУНТА"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.orange)
                                    .frame(width: 42, height: 42)
                                    .background(Circle().fill(Color.orange.opacity(0.11)))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(t("Plan Tier: Free Version", "Тариф: Безкоштовна версія"))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(t("Limited to 1 basic routine. Unlock the full recovery system.", "Лише 1 базова рутина. Відкрийте повну систему відновлення."))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }

                            Button(action: { showSubscriptionPaywall = true }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                    Text(t("Upgrade to PRO", "Оновитися до PRO"))
                                }
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    LinearGradient(colors: [Color.orange, Color.yellow.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                                .shadow(color: Color.orange.opacity(0.22), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(16)
                    }

                    // Картка особистих даних
                    VStack(alignment: .leading, spacing: 18) {
                        Text(t("PERSONAL INFO", "ОСОБИСТІ ДАНІ"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t("Name", "Ім'я"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                TextField(t("Enter your name", "Введіть ваше ім'я"), text: $userName)
                                    .font(.system(size: 16, weight: .medium))
                                    .textFieldStyle(.plain)
                            }

                            Divider()

                            Button(action: { showEmailSheet = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(t("Email", "Пошта"))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.gray)
                                        Text(userEmail)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue.opacity(0.7))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(16)
                    }

                    // Картка вибору мови (Preferences)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(t("PREFERENCES", "НАЛАШТУВАННЯ"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(t("Language", "Мова"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)

                            Picker(t("Language", "Мова"), selection: $appLanguage) {
                                Text("🇺🇸 EN").tag("en")
                                Text("🇺🇦 UA").tag("ua")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(16)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(16)
                    }

                    // Картка безпеки
                    VStack(alignment: .leading, spacing: 10) {
                        Text(t("SECURITY", "БЕЗПЕКА"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        Button(action: { showPasswordSheet = true }) {
                            HStack {
                                Label(t("Change Password", "Змінити пароль"), systemImage: "lock.shield")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                            .padding(16)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 20)

                    // Кнопка логауту
                    Button(action: {
                        withAnimation {
                            isLoggedIn = false
                            showProfile = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(t("Log Out", "Вийти"))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(14)
                        .shadow(color: Color.red.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(.background)
            .navigationTitle(t("Profile", "Профіль"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("Done", "Готово")) { showProfile = false }
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .sheet(isPresented: $showEmailSheet) {
                ChangeEmailView(showSheet: $showEmailSheet)
            }
            .sheet(isPresented: $showPasswordSheet) {
                ChangePasswordView(showSheet: $showPasswordSheet)
            }
            .fullScreenCover(isPresented: $showSubscriptionPaywall) {
                SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
            }
        }
        .frame(minWidth: 360, minHeight: 600)
    }
}

// --- БЕЗПЕЧНА ЗМІНА ПОШТИ ---
struct ChangeEmailView: View {
    @Binding var showSheet: Bool
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"
    @AppStorage("userPassword") var userPassword: String = "password123"

    @State private var newEmail = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(t("New Email Address", "Нова електронна пошта"))) {
                    TextField(t("Enter new email", "Введіть нову пошту"), text: $newEmail)
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text(t("Confirm Identity", "Підтвердьте особу")), footer: Text(t("You must enter your current password to change your email.", "Щоб змінити пошту, введіть поточний пароль."))) {
                    SecureField(t("Current Password", "Поточний пароль"), text: $confirmPassword)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Section {
                    Button(t("Save New Email", "Зберегти нову пошту")) {
                        if confirmPassword == userPassword {
                            userEmail = newEmail
                            showSheet = false
                        } else {
                            errorMessage = t("Incorrect password. Access denied.", "Неправильний пароль. Доступ заборонено.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(newEmail.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle(t("Change Email", "Змінити пошту"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Cancel", "Скасувати")) { showSheet = false }
                }
            }
        }
        .frame(minWidth: 320, minHeight: 300)
    }
}

// --- БЕЗПЕЧНА ЗМІНА ПАРОЛЯ ---
struct ChangePasswordView: View {
    @Binding var showSheet: Bool
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @AppStorage("userPassword") var userPassword: String = "password123"
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"

    @State private var currentPasswordInput = ""
    @State private var newPasswordInput = ""
    @State private var errorMessage = ""
    @State private var showForgotAlert = false

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(t("Verification", "Перевірка"))) {
                    SecureField(t("Current Password", "Поточний пароль"), text: $currentPasswordInput)

                    Button(t("Forgot Password?", "Забули пароль?")) {
                        showForgotAlert = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                }

                Section(header: Text(t("New Password", "Новий пароль"))) {
                    SecureField(t("Enter new password", "Введіть новий пароль"), text: $newPasswordInput)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Section {
                    Button(t("Update Password", "Оновити пароль")) {
                        if currentPasswordInput == userPassword {
                            if !newPasswordInput.isEmpty {
                                userPassword = newPasswordInput
                                showSheet = false
                            }
                        } else {
                            errorMessage = t("Current password is incorrect.", "Поточний пароль неправильний.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(currentPasswordInput.isEmpty || newPasswordInput.isEmpty)
                }
            }
            .navigationTitle(t("Update Password", "Оновити пароль"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Cancel", "Скасувати")) { showSheet = false }
                }
            }
            .alert(t("Reset Link Sent", "Посилання надіслано"), isPresented: $showForgotAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(t("We have successfully sent a password reset instruction to your registered email: \(userEmail)", "Ми надіслали інструкцію для скидання пароля на вашу зареєстровану пошту: \(userEmail)"))
            }
        }
        .frame(minWidth: 320, minHeight: 350)
    }
}

enum SubscriptionBillingPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .monthly: return language == "ua" ? "Місяць" : "Monthly"
        case .yearly: return language == "ua" ? "Рік" : "Yearly"
        }
    }

    func price(language: String) -> String {
        switch self {
        case .monthly: return "$4.99/mo"
        case .yearly: return "$29.99/yr"
        }
    }
}

struct SubscriptionPaywallView: View {
    @Binding var isPresented: Bool
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var selectedPlan: SubscriptionBillingPlan = .yearly
    @State private var pulse = false

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.blue.opacity(0.82), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.orange.opacity(0.22))
                .blur(radius: 46)
                .offset(x: 150, y: -260)
            Circle()
                .fill(Color.cyan.opacity(0.18))
                .blur(radius: 52)
                .offset(x: -150, y: 280)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack {
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.white.opacity(0.82))
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom))
                            .frame(width: 88, height: 88)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                            .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))

                        Text("ShramPlan PRO")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(t("Unlock the full recovery operating system before you enter the dashboard.", "Відкрийте повну операційну систему відновлення перед входом у панель."))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    billingSwitcher

                    VStack(spacing: 8) {
                        Text(selectedPlan.price(language: appLanguage))
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(t("Yearly saves 50% compared to monthly billing.", "Річний план заощаджує 50% порівняно з місячною оплатою."))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }

                    featureComparison

                    Button(action: { isPresented = false }) {
                        VStack(spacing: 4) {
                            Text(t("Activate ShramPlan PRO", "Активувати ShramPlan PRO"))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                            Text(selectedPlan == .yearly ? "$29.99/year" : "$4.99/month")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .opacity(0.82)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.orange.opacity(0.45), radius: pulse ? 28 : 12, x: 0, y: pulse ? 14 : 6)
                        )
                        .scaleEffect(pulse ? 1.025 : 1)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    Text(t("Subscription purchase flow placeholder. Connect StoreKit products when ready.", "Плейсхолдер покупки підписки. Підключіть продукти StoreKit, коли будете готові."))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.42))
                        .multilineTextAlignment(.center)
                }
                .padding(22)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var billingSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(SubscriptionBillingPlan.allCases) { plan in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedPlan = plan
                    }
                } label: {
                    VStack(spacing: 7) {
                        HStack(spacing: 5) {
                            Text(plan.title(language: appLanguage))
                            if plan == .yearly {
                                Text(t("🔥 SAVE 50%", "🔥 ЗАОЩАДЖУЙ 50%"))
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.yellow))
                            }
                        }
                        Text(plan.price(language: appLanguage))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .opacity(0.82)
                    }
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(selectedPlan == plan ? .black : .white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selectedPlan == plan ? Color.white : Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(selectedPlan == plan ? 0 : 0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("Free vs PRO", "Free проти PRO"))
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)

            HStack(spacing: 10) {
                PaywallPlanColumn(
                    title: t("Free Plan", "Безкоштовно"),
                    subtitle: t("1-day trial feel", "Майже пробний режим"),
                    color: .gray,
                    rows: [
                        t("Max 1 basic routine", "Макс. 1 базова рутина"),
                        t("0 Quit Challenges", "0 викликів відмови"),
                        t("No advanced graphs", "Без просунутих графіків"),
                        t("Local storage only", "Лише локальне сховище")
                    ],
                    isPro: false
                )

                PaywallPlanColumn(
                    title: "ShramPlan PRO",
                    subtitle: t("Full recovery system", "Повна система відновлення"),
                    color: .orange,
                    rows: [
                        t("Unlimited habits", "Безлімітні звички"),
                        t("Unrestricted Quit Challenges + Healing Metrics", "Безлімітні відмови + метрики зцілення"),
                        t("Apple Card-style Finance tracking", "Фінанси у стилі Apple Card"),
                        t("iCloud backup", "Резервна копія iCloud")
                    ],
                    isPro: true
                )
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

struct PaywallPlanColumn: View {
    let title: String
    let subtitle: String
    let color: Color
    let rows: [String]
    let isPro: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            ForEach(rows, id: \.self) { row in
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: isPro ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isPro ? .green : .red.opacity(0.82))
                    Text(row)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(isPro ? 0.88 : 0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(color.opacity(isPro ? 0.18 : 0.08)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(color.opacity(isPro ? 0.42 : 0.16), lineWidth: 1))
    }
}

// --- УНІВЕРСАЛЬНА АВАТАРКА ---
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
                        .scaledToFill()
                } else { fallbackSystemIcon }
                #else
                if let uiImage = UIImage(data: customData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else { fallbackSystemIcon }
                #endif
            } else {
                fallbackSystemIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallbackSystemIcon: some View {
        Image(systemName: iconName.isEmpty ? "person.crop.circle.fill" : iconName)
            .resizable()
            .scaledToFit()
            .foregroundColor(.blue)
    }
}
