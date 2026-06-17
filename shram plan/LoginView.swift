import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("showPostLoginPaywall") var showPostLoginPaywall: Bool = false

    @State private var isSignUpMode = false
    @State private var showSubscriptionPaywall = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.scarlet.opacity(0.12), Color.scarlet.opacity(0.01)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Circle()
                            .stroke(Color.scarlet.opacity(0.08), lineWidth: 1)
                            .frame(width: 100, height: 100)

                        Image(systemName: "bandage.fill")
                            .font(.system(size: 38, weight: .regular))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.scarlet)
                            .shadow(color: Color.scarlet.opacity(0.2), radius: 8, x: 0, y: 4)
                    }

                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            Text("Shram")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Plan")
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .foregroundColor(.scarlet)
                        }

                        Text(isSignUpMode ? "Start your journey to healing and growth." : "Your personal growth dashboard is waiting.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                VStack(spacing: 14) {
                    if isSignUpMode {
                        HStack(spacing: 12) {
                            Image(systemName: "person")
                                .foregroundColor(.scarlet.opacity(0.6))
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 20)

                            TextField("Your Name", text: $name)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .foregroundColor(.scarlet.opacity(0.6))
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 20)

                        TextField("Email address", text: $email)
                            .font(.system(size: 15, weight: .medium))
                            .textInputAutocapitalization(.never)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )

                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .foregroundColor(.scarlet.opacity(0.6))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 20)

                        SecureField("Password", text: $password)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )
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
                        Text(isSignUpMode ? "Get Started" : "Sign In")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color.scarlet, Color.scarlet.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.scarlet.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSignUpMode.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            Text(isSignUpMode ? "Log In" : "Sign Up")
                                .fontWeight(.bold)
                                .foregroundColor(.scarlet)
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(24)
        }
        .fullScreenCover(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
        }
    }
}
