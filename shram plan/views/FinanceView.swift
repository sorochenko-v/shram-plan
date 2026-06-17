import SwiftUI
import Charts
#if canImport(UIKit)
import UIKit
#endif

struct FinanceView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 38, weight: .ultraLight))
                    .foregroundColor(.secondary.opacity(0.25))

                Text("Finance Tracker")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.35))

                Text("Coming soon")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.2))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ImpulsePreset: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let englishTitle: String
    let color: Color

    var title: String {
        englishTitle
    }

    static let defaults: [ImpulsePreset] = [
        ImpulsePreset(emoji: "☕️", englishTitle: "Coffee", color: .brown),
        ImpulsePreset(emoji: "🚬", englishTitle: "Tobacco", color: .red),
        ImpulsePreset(emoji: "🍔", englishTitle: "Fast Food", color: .orange),
        ImpulsePreset(emoji: "🛍️", englishTitle: "Shopping", color: .purple),
        ImpulsePreset(emoji: "🎮", englishTitle: "Gaming", color: .blue)
    ]

    static var custom: ImpulsePreset {
        ImpulsePreset(
            emoji: "✨",
            englishTitle: "Avoided Impulse",
            color: .green
        )
    }
}

struct WillpowerLog: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var amount: Double
    var date: Date
}

struct DisciplinePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ImpulseTile: View {
    let preset: ImpulsePreset
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(preset.emoji)
                        .font(.system(size: 28))
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(preset.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Capture saved money")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(preset.color.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct LeakControlRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
                .frame(width: 42, height: 42)
                .background(Circle().fill(color.opacity(0.08)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

struct WillpowerTimelineRow: View {
    let log: WillpowerLog

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 2, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(log.title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text(log.date, style: .time)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "+%.2f US$", log.amount))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.green)
        }
        .padding(13)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

struct AvoidedImpulseLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let preset: ImpulsePreset
    var onSave: (String, Double) -> Void

    @State private var amountText = ""
    @State private var title = ""

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    Text(preset.emoji)
                        .font(.system(size: 46))
                        .frame(width: 82, height: 82)
                        .background(Circle().fill(preset.color.opacity(0.1)))

                    Text(preset.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("How much did you save by skipping this today?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title", text: $title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .textFieldStyle(.plain)

                    Divider()

                    TextField("0.00 US$", text: $amountText)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .foregroundColor(.green)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.68))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )

                Spacer()

                Button {
                    onSave(title.isEmpty ? preset.title : title, amount)
                    dismiss()
                } label: {
                    Text("Save Discipline Win")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.green)
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .disabled(amount <= 0)
                .opacity(amount <= 0 ? 0.45 : 1)
            }
            .padding(20)
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                title = preset.title
            }
        }
    }
}

extension View {
    func financeCard(cornerRadius: CGFloat) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.035), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack {
        FinanceView()
    }
}
