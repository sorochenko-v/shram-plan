import SwiftUI
import Charts
#if canImport(UIKit)
import UIKit
#endif

struct FinanceView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    @State private var savedLogs: [WillpowerLog] = []
    @State private var selectedImpulse: ImpulsePreset?
    @State private var showLogSheet = false

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    private var totalSaved: Double {
        savedLogs.reduce(0) { $0 + $1.amount }
    }

    private var disciplinePoints: [DisciplinePoint] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
        var runningTotal = 0.0
        var points = [DisciplinePoint(date: start, value: 0)]

        for log in savedLogs.sorted(by: { $0.date < $1.date }) {
            runningTotal += log.amount
            points.append(DisciplinePoint(date: log.date, value: runningTotal))
        }

        points.append(DisciplinePoint(date: end, value: runningTotal))
        return points
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                disciplineWealthCard
                quickWillpowerLog
                leaksControl
                willpowerHistory
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [Color.primary.opacity(0.012), Color.green.opacity(0.014), Color.blue.opacity(0.012)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showLogSheet) {
            AvoidedImpulseLogSheet(language: appLanguage, preset: selectedImpulse ?? ImpulsePreset.defaults[0]) { title, amount in
                logSavedImpulse(title: title, amount: amount)
            }
        }
    }

    private var disciplineWealthCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DISCIPLINE WEALTH")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.green.opacity(0.85))
                        .tracking(1.8)

                    Text(t("Impulse money recovered into identity capital", "Імпульсивні гроші повернено в капітал ідентичності"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.green.opacity(0.09)))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(currencyPrecise(totalSaved))
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(t("Saved from impulses today", "Заощаджено від імпульсів сьогодні"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Button {
                triggerHaptic()
                selectedImpulse = ImpulsePreset.custom(language: appLanguage)
                showLogSheet = true
            } label: {
                HStack(spacing: 10) {
                    Text("＋")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                    Text(t("Log Avoided Impulse", "Зафіксувати уникнену витрату"))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .black))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color.green, Color.blue.opacity(0.88)], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: Color.green.opacity(0.22), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            disciplineCurve
        }
        .padding(20)
        .financeCard(cornerRadius: 28)
    }

    private var disciplineCurve: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(t("Wealth Recovery Flow", "Потік відновлення капіталу"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text("0%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Chart(disciplinePoints) { point in
                AreaMark(
                    x: .value(t("Time", "Час"), point.date),
                    y: .value(t("Saved", "Заощаджено"), point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(colors: [Color.green.opacity(0.24), Color.blue.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom)
                )

                LineMark(
                    x: .value(t("Time", "Час"), point.date),
                    y: .value(t("Saved", "Заощаджено"), point.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .foregroundStyle(LinearGradient(colors: [Color.green, Color.cyan], startPoint: .leading, endPoint: .trailing))
                .shadow(color: Color.green.opacity(0.3), radius: 8)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...max(1, totalSaved))
            .frame(height: 120)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.primary.opacity(0.018))
                    .cornerRadius(16)
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(18)
    }

    private var quickWillpowerLog: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t("QUICK WILLPOWER LOG", "ШВИДКА ФІКСАЦІЯ СПОКУС"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.green.opacity(0.85))
                    .tracking(1.4)

                Text(t("Tap a temptation you skipped and capture the saved money.", "Натисніть спокусу, яку пропустили, і зафіксуйте збережені гроші."))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ImpulsePreset.defaults) { preset in
                    ImpulseTile(preset: preset, language: appLanguage) {
                        triggerHaptic()
                        selectedImpulse = preset
                        showLogSheet = true
                    }
                }
            }
        }
    }

    private var leaksControl: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("FINANCIAL LEAKS CONTROL", "КОНТРОЛЬ ФІНАНСОВИХ ВТРАТ"))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.red.opacity(0.78))
                .tracking(1.4)

            VStack(spacing: 10) {
                LeakControlRow(
                    icon: "drop.triangle.fill",
                    title: t("System Leaks", "Системні втрати"),
                    subtitle: t("Impulse drains and recurring friction", "Імпульсивні зливи та повторюваний тертя"),
                    value: currencyPrecise(0),
                    color: .red
                )

                LeakControlRow(
                    icon: "link.circle.fill",
                    title: t("Tethered Burdens", "Прив'язані борги"),
                    subtitle: t("Obligations pulling attention backward", "Зобов'язання, що тягнуть увагу назад"),
                    value: currencyPrecise(0),
                    color: .orange
                )
            }
        }
        .padding(18)
        .financeCard(cornerRadius: 24)
    }

    private var willpowerHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(t("HISTORY OF WILLPOWER", "ІСТОРІЯ СИЛИ ВОЛІ"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.blue.opacity(0.8))
                    .tracking(1.4)
                Spacer()
                Text(currencyPrecise(totalSaved))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.green)
            }

            if savedLogs.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.blue.opacity(0.08)))

                    Text(t("Your discipline hasn't been tested yet today. Log your first saved expense above!", "Сьогодні вашу дисципліну ще не перевіряли. Зафіксуйте першу збережену витрату вище!"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(14)
                .background(Color.blue.opacity(0.035))
                .cornerRadius(18)
            } else {
                VStack(spacing: 10) {
                    ForEach(savedLogs.sorted(by: { $0.date > $1.date })) { log in
                        WillpowerTimelineRow(log: log, language: appLanguage)
                    }
                }
            }
        }
        .padding(18)
        .financeCard(cornerRadius: 24)
    }

    private func logSavedImpulse(title: String, amount: Double) {
        triggerHaptic()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            savedLogs.insert(
                WillpowerLog(title: title, amount: amount, date: Date()),
                at: 0
            )
        }
    }

    private func currencyPrecise(_ value: Double) -> String {
        String(format: "%.2f US$", value)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}

struct ImpulsePreset: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let englishTitle: String
    let ukrainianTitle: String
    let color: Color

    func title(language: String) -> String {
        language == "ua" ? ukrainianTitle : englishTitle
    }

    static let defaults: [ImpulsePreset] = [
        ImpulsePreset(emoji: "☕️", englishTitle: "Coffee", ukrainianTitle: "Кава", color: .brown),
        ImpulsePreset(emoji: "🚬", englishTitle: "Tobacco", ukrainianTitle: "Тютюн", color: .red),
        ImpulsePreset(emoji: "🍔", englishTitle: "Fast Food", ukrainianTitle: "Фастфуд", color: .orange),
        ImpulsePreset(emoji: "🛍️", englishTitle: "Shopping", ukrainianTitle: "Покупки", color: .purple),
        ImpulsePreset(emoji: "🎮", englishTitle: "Gaming", ukrainianTitle: "Ігри", color: .blue)
    ]

    static func custom(language: String) -> ImpulsePreset {
        ImpulsePreset(
            emoji: "✨",
            englishTitle: "Avoided Impulse",
            ukrainianTitle: "Уникнена спокуса",
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
    let language: String
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
                    Text(preset.title(language: language))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text(language == "ua" ? "Зафіксувати економію" : "Capture saved money")
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
    let language: String

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

    let language: String
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

                    Text(preset.title(language: language))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(language == "ua" ? "Скільки ви зберегли, пропустивши це сьогодні?" : "How much did you save by skipping this today?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 16) {
                    TextField(language == "ua" ? "Назва" : "Title", text: $title)
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
                    onSave(title.isEmpty ? preset.title(language: language) : title, amount)
                    dismiss()
                } label: {
                    Text(language == "ua" ? "Зберегти дисципліну" : "Save Discipline Win")
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
            .navigationTitle(language == "ua" ? "Фіксація" : "Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == "ua" ? "Скасувати" : "Cancel") { dismiss() }
                }
            }
            .onAppear {
                title = preset.title(language: language)
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
