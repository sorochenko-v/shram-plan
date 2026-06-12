import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("appLanguage") var appLanguage: String = "en"
    @AppStorage("showPostLoginPaywall") var showPostLoginPaywall: Bool = false

    @State private var isSignUpMode = false
    @State private var showSubscriptionPaywall = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)

                    Circle()
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                        .frame(width: 110, height: 110)

                    Image(systemName: "bandage.fill")
                        .font(.system(size: 42, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.blue)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Shram")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Plan")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .foregroundColor(.blue)
                    }

                    Text(isSignUpMode ? t("Start your journey to healing and growth.", "Почніть шлях до відновлення та зростання.") : t("Your personal growth dashboard is waiting.", "Ваша персональна панель зростання вже чекає."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            VStack(spacing: 14) {
                if isSignUpMode {
                    HStack(spacing: 12) {
                        Image(systemName: "person")
                            .foregroundColor(.blue.opacity(0.6))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 20)

                        TextField(t("Your Name", "Ваше ім'я"), text: $name)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding()
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundColor(.blue.opacity(0.6))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 20)

                    TextField(t("Email address", "Електронна пошта"), text: $email)
                        .font(.system(size: 15, weight: .medium))
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(16)

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundColor(.blue.opacity(0.6))
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 20)

                    SecureField(t("Password", "Пароль"), text: $password)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(16)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 20) {
                Button(action: {
                    showPostLoginPaywall = true
                    showSubscriptionPaywall = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isLoggedIn = true
                    }
                }) {
                    Text(isSignUpMode ? t("Get Started", "Почати") : t("Sign In", "Увійти"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSignUpMode.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isSignUpMode ? t("Already have an account?", "Вже маєте акаунт?") : t("Don't have an account?", "Немає акаунта?"))
                            .foregroundColor(.gray)
                        Text(isSignUpMode ? t("Log In", "Увійти") : t("Sign Up", "Зареєструватися"))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(24)
        .background(.background)
        .fullScreenCover(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
        }
    }
}
