import SwiftUI

struct SubscriptionPaywallView: View {
    @Binding var isPresented: Bool
    @State private var selectedPlan: SubscriptionBillingPlan = .yearly
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Frosted glass background layout
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [Color.blue.opacity(0.03), Color(red: 0.68, green: 0.58, blue: 0.40).opacity(0.04), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Top Space / Spacer
                    Spacer(minLength: 20)

                    // Abstract outline gold crown
                    VStack(spacing: 16) {
                        Image(systemName: "crown")
                            .font(.system(size: 52, weight: .ultraLight))
                            .foregroundColor(Color(red: 0.68, green: 0.58, blue: 0.40))
                            .scaleEffect(pulse ? 1.04 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)
                            .onAppear { pulse = true }

                        VStack(spacing: 8) {
                            Text("Shram Plan Pro")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(0.5)

                            Text("Elevate your personal accountability. Unlock full performance metrics.")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .lineSpacing(3)
                        }
                    }

                    // Plan Cards Section
                    VStack(spacing: 12) {
                        ForEach(SubscriptionBillingPlan.allCases) { plan in
                            NewPlanCard(plan: plan, isSelected: selectedPlan == plan) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPlan = plan
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Thinner Continue Button
                    VStack(spacing: 16) {
                        Button {
                            // Purchase logic integration
                            isPresented = false
                        } label: {
                            Text("Continue with \(selectedPlan.titleName)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)

                        Button {
                            // Restore purchase logic
                            isPresented = false
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .opacity(0.3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Minimalist Legal Links & Text
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                            Text("•")
                            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        }
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .opacity(0.2)

                        Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .opacity(0.18)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 48)
                            .lineSpacing(2)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct MostPopularBadgeView: View {
    var body: some View {
        Text("MOST POPULAR • SAVED 50%")
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundColor(Color(red: 0.68, green: 0.58, blue: 0.40))
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(red: 0.68, green: 0.58, blue: 0.40).opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(red: 0.68, green: 0.58, blue: 0.40).opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(6)
    }
}

struct NewPlanCard: View {
    let plan: SubscriptionBillingPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.primary.opacity(0.12), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(plan.titleName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if plan == .yearly {
                            MostPopularBadgeView()
                        }
                    }
                    
                    Text(plan.pricingDetail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.35))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue.opacity(0.25) : Color.primary.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

extension SubscriptionBillingPlan {
    var titleName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var pricingDetail: String {
        switch self {
        case .monthly: return "$4.99 / month"
        case .yearly: return "$29.99 / year"
        }
    }
}

enum SubscriptionBillingPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }
}
