import SwiftUI

struct HabitItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var streak: Int
    var isCompleted: Bool
    var weeklyCompletion: [Bool]

    init(id: UUID = UUID(), name: String, icon: String, streak: Int = 0, isCompleted: Bool = false, weeklyCompletion: [Bool] = Array(repeating: false, count: 7)) {
        self.id = id
        self.name = name
        self.icon = icon
        self.streak = streak
        self.isCompleted = isCompleted
        self.weeklyCompletion = weeklyCompletion
    }
}

enum QuitTrackingMode: String, CaseIterable, Equatable {
    case financial
    case time
    case pureWillpower

    func title(language: String) -> String {
        switch self {
        case .financial:
            return language == "ua" ? "Фінанси" : "Financial"
        case .time:
            return language == "ua" ? "Час" : "Time"
        case .pureWillpower:
            return language == "ua" ? "Воля" : "Willpower"
        }
    }

    var icon: String {
        switch self {
        case .financial: return "dollarsign.circle.fill"
        case .time: return "clock.fill"
        case .pureWillpower: return "brain.head.profile"
        }
    }

    var accent: Color {
        switch self {
        case .financial: return .green
        case .time: return .blue
        case .pureWillpower: return .purple
        }
    }
}

enum ChallengeStatus: String, Equatable {
    case clean
    case relapsed
    case unmarked
}

struct AdvancedQuitItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var startDate: Date
    var trackingMode: QuitTrackingMode
    var dailyImpactValue: Double
    var history: [Date: ChallengeStatus]
    var healingScore: Double

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        startDate: Date = Date(),
        trackingMode: QuitTrackingMode,
        dailyImpactValue: Double = 0,
        history: [Date: ChallengeStatus] = [:],
        healingScore: Double = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.trackingMode = trackingMode
        self.dailyImpactValue = dailyImpactValue
        self.history = history
        self.healingScore = healingScore
    }

    var cleanDays: Int {
        history.values.filter { $0 == .clean }.count
    }

    var relapseDays: Int {
        history.values.filter { $0 == .relapsed }.count
    }

    var accumulatedImpact: Double {
        Double(cleanDays) * dailyImpactValue
    }

    func status(for date: Date) -> ChallengeStatus {
        history[Calendar.current.startOfDay(for: date)] ?? .unmarked
    }

    func consecutiveCleanDays(endingAt endDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: endDate)
        var count = 0

        while date >= startDate {
            guard status(for: date) == .clean else { break }
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }

        return count
    }
}

struct HabitsView: View {
    @AppStorage("appLanguage") var appLanguage: String = "en"

    @Binding var showAddModal: Bool

    @State private var activeHabits: [HabitItem] = []
    @State private var activeQuits: [AdvancedQuitItem] = []

    var currentWeekdayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    @State private var suggestedHabits = [
        HabitItem(name: "Gym Workout", icon: "figure.cross.training"),
        HabitItem(name: "Healthy Sleep", icon: "bed.double.fill"),
        HabitItem(name: "Hydrate", icon: "drop.fill")
    ]

    @State private var suggestedQuits = [
        AdvancedQuitItem(name: "Quit Smoking", icon: "smoke.fill", trackingMode: .financial, dailyImpactValue: 6),
        AdvancedQuitItem(name: "No TikTok Scrolling", icon: "iphone", trackingMode: .time, dailyImpactValue: 2),
        AdvancedQuitItem(name: "No Alcohol", icon: "wineglass.fill", trackingMode: .financial, dailyImpactValue: 15)
    ]

    @State private var habitToEdit: HabitItem? = nil
    @State private var quitToEdit: AdvancedQuitItem? = nil

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        List {
            Text(t("Build the good. Break what keeps taking from you.", "Будуйте корисне. Ламайте те, що забирає у вас сили."))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 12, trailing: 24))

            if activeHabits.isEmpty && activeQuits.isEmpty {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.04))
                                .frame(width: 80, height: 80)
                            Image(systemName: "sparkles")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.blue.opacity(0.6))
                        }

                        Text(t("Your Dashboard is Clean", "Ваша панель чиста"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text(t("Start healing your life. Pick a curated recommendation below or craft your own setup.", "Почніть відновлювати своє життя. Оберіть готову рекомендацію нижче або створіть власний план."))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 24)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: t("SUGGESTED ROUTINES", "РЕКОМЕНДОВАНІ РУТИНИ"))
                        ForEach(suggestedHabits) { habit in
                            SuggestionButton(title: localizedPlanName(habit.name, language: appLanguage), icon: habit.icon, color: .blue) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    activeHabits.append(habit)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: t("SUGGESTED QUIT CHALLENGES", "РЕКОМЕНДОВАНІ ВІДМОВИ"))
                        ForEach(suggestedQuits) { quit in
                            AdvancedQuitSuggestionButton(quit: quit, language: appLanguage) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    activeQuits.append(freshChallenge(from: quit))
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24))
            } else {
                if !activeHabits.isEmpty {
                    Section(header: SectionHeader(title: t("DAILY ROUTINES", "ЩОДЕННІ РУТИНИ"), subtitle: t("Small wins that compound", "Малі перемоги, що накопичуються")).padding(.leading, 4)) {
                        ForEach(activeHabits) { habit in
                            HabitCard(habit: habit, language: appLanguage, onToggle: {
                                if let idx = activeHabits.firstIndex(where: { $0.id == habit.id }) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        let today = currentWeekdayIndex
                                        activeHabits[idx].isCompleted.toggle()
                                        activeHabits[idx].weeklyCompletion[today] = activeHabits[idx].isCompleted

                                        if activeHabits[idx].isCompleted {
                                            activeHabits[idx].streak += 1
                                        } else {
                                            activeHabits[idx].streak = max(0, activeHabits[idx].streak - 1)
                                        }
                                    }
                                }
                            })
                            .contextMenu {
                                Button { habitToEdit = habit } label: { Label(t("Edit Habit", "Редагувати звичку"), systemImage: "pencil") }
                                Button(role: .destructive) { withAnimation { activeHabits.removeAll { $0.id == habit.id } } } label: { Label(t("Delete", "Видалити"), systemImage: "trash") }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation { activeHabits.removeAll { $0.id == habit.id } }
                                } label: { Image(systemName: "trash") }

                                Button { habitToEdit = habit } label: { Image(systemName: "pencil") }
                                    .tint(.orange)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    }
                }

                if !activeQuits.isEmpty {
                    Section(header: SectionHeader(title: t("QUIT CHALLENGES", "ВІДМОВИ"), subtitle: t("Healing old scars with visible progress", "Загоєння старих шрамів через видимий прогрес")).padding(.leading, 4)) {
                        ForEach(activeQuits) { quit in
                            AdvancedQuitCard(quit: quit, language: appLanguage) { date in
                                updateChallenge(quit, on: date)
                            }
                            .contextMenu {
                                Button { quitToEdit = quit } label: { Label(t("Edit Challenge", "Редагувати виклик"), systemImage: "pencil") }
                                Button(role: .destructive) { withAnimation { activeQuits.removeAll { $0.id == quit.id } } } label: { Label(t("Delete", "Видалити"), systemImage: "trash") }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation { activeQuits.removeAll { $0.id == quit.id } }
                                } label: { Image(systemName: "trash") }

                                Button { quitToEdit = quit } label: { Image(systemName: "pencil") }
                                    .tint(.orange)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.primary.opacity(0.015))
        .sheet(isPresented: $showAddModal) {
            AddHabitLuxuryView(initialName: "", initialIcon: "⭐️", isQuitMode: false, titleLabel: t("Create ShramPlan", "Створити ShramPlan")) { name, icon, isQuit, trackingMode, dailyImpact in
                withAnimation(.spring()) {
                    if isQuit {
                        activeQuits.append(
                            AdvancedQuitItem(
                                name: name,
                                icon: icon,
                                trackingMode: trackingMode,
                                dailyImpactValue: trackingMode == .pureWillpower ? 0 : dailyImpact
                            )
                        )
                    } else {
                        activeHabits.append(HabitItem(name: name, icon: icon))
                    }
                }
            }
        }
        .sheet(item: $habitToEdit) { habit in
            AddHabitLuxuryView(initialName: localizedPlanName(habit.name, language: appLanguage), initialIcon: habit.icon, isQuitMode: false, titleLabel: t("Edit Routine", "Редагувати рутину")) { name, icon, _, _, _ in
                if let idx = activeHabits.firstIndex(where: { $0.id == habit.id }) {
                    activeHabits[idx].name = name
                    activeHabits[idx].icon = icon
                }
            }
        }
        .sheet(item: $quitToEdit) { quit in
            AddHabitLuxuryView(
                initialName: localizedPlanName(quit.name, language: appLanguage),
                initialIcon: quit.icon,
                isQuitMode: true,
                titleLabel: t("Edit Challenge", "Редагувати виклик"),
                initialTrackingMode: quit.trackingMode,
                initialImpactValue: quit.dailyImpactValue
            ) { name, icon, _, trackingMode, dailyImpact in
                if let idx = activeQuits.firstIndex(where: { $0.id == quit.id }) {
                    activeQuits[idx].name = name
                    activeQuits[idx].icon = icon
                    activeQuits[idx].trackingMode = trackingMode
                    activeQuits[idx].dailyImpactValue = trackingMode == .pureWillpower ? 0 : dailyImpact
                    activeQuits[idx].healingScore = healingScore(for: activeQuits[idx])
                }
            }
        }
    }

    private func freshChallenge(from challenge: AdvancedQuitItem) -> AdvancedQuitItem {
        AdvancedQuitItem(
            name: challenge.name,
            icon: challenge.icon,
            trackingMode: challenge.trackingMode,
            dailyImpactValue: challenge.dailyImpactValue
        )
    }

    private func updateChallenge(_ challenge: AdvancedQuitItem, on date: Date) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        guard day <= calendar.startOfDay(for: Date()) else { return }

        guard let index = activeQuits.firstIndex(where: { $0.id == challenge.id }) else { return }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
            let currentStatus = activeQuits[index].history[day] ?? .unmarked
            let nextStatus: ChallengeStatus

            switch currentStatus {
            case .unmarked:
                nextStatus = .clean
            case .clean:
                nextStatus = .relapsed
            case .relapsed:
                nextStatus = .unmarked
            }

            if nextStatus == .unmarked {
                activeQuits[index].history.removeValue(forKey: day)
            } else {
                activeQuits[index].history[day] = nextStatus
            }

            activeQuits[index].healingScore = healingScore(for: activeQuits[index])
        }
    }
}

struct HabitCard: View {
    let habit: HabitItem
    let language: String
    var onToggle: () -> Void

    private var daysLetters: [String] {
        language == "ua" ? ["Пн", "Вв", "Ср", "Чт", "Пт", "Сб", "Нд"] : ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.06))
                        .frame(width: 42, height: 42)
                    HabitIconView(icon: habit.icon, color: .blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(localizedPlanName(habit.name, language: language))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(language == "ua" ? "🔥 стрік: \(habit.streak) днів" : "🔥 \(habit.streak) days streak")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(habit.isCompleted ? Color.green : Color.primary.opacity(0.03))
                            .frame(width: 32, height: 32)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(habit.isCompleted ? .white : .clear)
                    }
                    .overlay(
                        Circle()
                            .stroke(habit.isCompleted ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1.5)
                    )
                    .scaleEffect(habit.isCompleted ? 1.05 : 1.0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language == "ua" ? "Позначити виконання" : "Toggle completion")
            }

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(
                                habit.weeklyCompletion[dayIndex] ?
                                LinearGradient(colors: [Color.blue, Color.blue.opacity(0.75)], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [Color.primary.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: 14)
                            .shadow(color: habit.weeklyCompletion[dayIndex] ? Color.blue.opacity(0.25) : Color.clear, radius: 4, y: 2)

                        Text(daysLetters[dayIndex])
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.03), lineWidth: 1)
        )
    }
}

struct AdvancedQuitCard: View {
    let quit: AdvancedQuitItem
    let language: String
    var onToggleDay: (Date) -> Void

    private var accent: Color { quit.trackingMode.accent }
    private var calendar: Calendar { Calendar.current }
    private var visibleDates: [Date] {
        (-2...2).compactMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: Date())) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.08))
                        .frame(width: 48, height: 48)
                    HabitIconView(icon: quit.icon, color: accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(localizedPlanName(quit.name, language: language))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(milestoneTitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                }

                Spacer()

                HealingScoreBadge(score: quit.healingScore, language: language)
            }

            HStack(spacing: 8) {
                MetricPill(text: cleanDaysText, color: .red)
                MetricPill(text: impactText, color: quit.trackingMode == .pureWillpower ? .purple : .green)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(language == "ua" ? "ОСТАННІ 5 ДНІВ" : "LAST 5 DAYS")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.gray.opacity(0.7))
                    .tracking(1)

                HStack(spacing: 8) {
                    ForEach(visibleDates, id: \.self) { date in
                        ChallengeDayCell(
                            date: date,
                            status: quit.status(for: date),
                            isFuture: calendar.startOfDay(for: date) > calendar.startOfDay(for: Date()),
                            language: language
                        ) {
                            onToggleDay(date)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.025))
            .cornerRadius(16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.11), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var cleanDaysText: String {
        language == "ua" ? "⏳ Чисто: \(quit.cleanDays) дн" : "⏳ \(quit.cleanDays) Days Clean"
    }

    private var impactText: String {
        switch quit.trackingMode {
        case .financial:
            return language == "ua" ? "💰 Заощаджено: $\(Int(quit.accumulatedImpact))" : "💰 Saved: $\(Int(quit.accumulatedImpact))"
        case .time:
            return language == "ua" ? "⏱️ Повернено: \(formattedImpact) год" : "⏱️ Recovered: \(formattedImpact)h"
        case .pureWillpower:
            return language == "ua" ? "🧠 Ясність: активна" : "🧠 Clarity: active"
        }
    }

    private var formattedImpact: String {
        let value = quit.accumulatedImpact
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private var milestoneTitle: String {
        milestoneFor(days: quit.consecutiveCleanDays(), language: language)
    }
}

struct HealingScoreBadge: View {
    let score: Double
    let language: String

    var body: some View {
        VStack(spacing: 2) {
            Text("🧬")
                .font(.system(size: 14))
            Text(language == "ua" ? "Зцілено" : "Healed")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundColor(.secondary)
            Text("\(Int(score.rounded()))%")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(width: 74, height: 58)
        .background(Color.primary.opacity(0.035))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct MetricPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(0.075))
            .cornerRadius(10)
    }
}

struct ChallengeDayCell: View {
    let date: Date
    let status: ChallengeStatus
    let isFuture: Bool
    let language: String
    var action: () -> Void

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Text(dayLabel)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.gray.opacity(isFuture ? 0.35 : 0.7))

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(backgroundColor)
                        .frame(height: 38)

                    Image(systemName: symbolName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(symbolColor)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.45 : 1)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dayLabel: String {
        if calendar.isDateInToday(date) {
            return language == "ua" ? "Сь" : "Today"
        }

        let weekday = calendar.component(.weekday, from: date)
        let english = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        let ukrainian = ["Нд", "Пн", "Вв", "Ср", "Чт", "Пт", "Сб"]
        return language == "ua" ? ukrainian[weekday - 1] : english[weekday - 1]
    }

    private var symbolName: String {
        switch status {
        case .clean: return "checkmark"
        case .relapsed: return "xmark"
        case .unmarked: return "minus"
        }
    }

    private var symbolColor: Color {
        switch status {
        case .clean: return .white
        case .relapsed: return .white
        case .unmarked: return .gray.opacity(0.45)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .clean: return .green
        case .relapsed: return .red
        case .unmarked: return Color.primary.opacity(0.035)
        }
    }

    private var accessibilityLabel: String {
        language == "ua" ? "Змінити статус дня" : "Toggle day status"
    }
}

struct AdvancedQuitSuggestionButton: View {
    let quit: AdvancedQuitItem
    let language: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(quit.trackingMode.accent.opacity(0.07))
                        .frame(width: 42, height: 42)
                    HabitIconView(icon: quit.icon, color: quit.trackingMode.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedPlanName(quit.name, language: language))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(quit.trackingMode.accent)
                    .padding(8)
                    .background(quit.trackingMode.accent.opacity(0.08))
                    .clipShape(Circle())
            }
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.4))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.02), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        switch quit.trackingMode {
        case .financial:
            return language == "ua" ? "$\(Int(quit.dailyImpactValue)) на день" : "$\(Int(quit.dailyImpactValue)) per day"
        case .time:
            return language == "ua" ? "\(formattedValue) год на день" : "\(formattedValue)h per day"
        case .pureWillpower:
            return language == "ua" ? "Без вартості, тільки сила волі" : "No cost, pure discipline"
        }
    }

    private var formattedValue: String {
        quit.dailyImpactValue.rounded() == quit.dailyImpactValue ? String(Int(quit.dailyImpactValue)) : String(format: "%.1f", quit.dailyImpactValue)
    }
}

struct SuggestionButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.06))
                        .frame(width: 38, height: 38)
                    HabitIconView(icon: icon, color: color)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.08))
                    .clipShape(Circle())
            }
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.4))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.02), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AddHabitLuxuryView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appLanguage") var appLanguage: String = "en"

    var initialName: String
    var initialIcon: String
    var isQuitMode: Bool
    var titleLabel: String
    var initialTrackingMode: QuitTrackingMode = .financial
    var initialImpactValue: Double = 6
    var onSave: (String, String, Bool, QuitTrackingMode, Double) -> Void

    @State private var name = ""
    @State private var isQuit = false
    @State private var iconCategorySelection = 0
    @State private var selectedIcon = "⭐️"
    @State private var userCustomEmoji = ""
    @State private var selectedTrackingMode: QuitTrackingMode = .financial
    @State private var financialImpact: Double = 6
    @State private var financialImpactText = "6.00"
    @State private var selectedCurrency: SupportedCurrency = .usd
    @State private var selectedTimeUnit: TimeInputUnit = .hours
    @State private var timeImpactValue: Double = 2
    @State private var timeImpactText = "2"

    let emojis = ["🍏", "💪", "💧", "😴", "📚", "🧘‍♂️", "🚭", "📱", "🍺", "☕️", "💵", "🧠", "🥗", "🏃‍♂️", "🎯", "🚫", "⏰", "🚴‍♂️", "🏋️‍♂️", "🥛"]
    let icons = ["star.fill", "bolt.fill", "heart.fill", "figure.cross.training", "book.fill", "leaf.fill", "drop.fill", "moon.stars.fill", "smoke.fill", "wineglass.fill", "iphone", "pill.fill", "cup.and.saucer.fill", "clock.fill", "shield.fill", "flame.fill", "calendar", "chart.bar.fill", "dollarsign.circle.fill", "brain"]

    let gridColumns = [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)]

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        Button(t("Good Habit", "Корисна звичка")) { withAnimation { isQuit = false } }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isQuit ? Color.clear : Color.blue.opacity(0.1))
                            .foregroundColor(isQuit ? .gray : .blue)
                        Button(t("Quit Challenge", "Відмова")) { withAnimation { isQuit = true } }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isQuit ? Color.red.opacity(0.1) : Color.clear)
                            .foregroundColor(isQuit ? .red : .gray)
                    }
                    .font(.system(size: 14, weight: .bold))
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(14)

                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(primaryAccent.opacity(0.08))
                                .frame(width: 64, height: 64)
                            HabitIconView(icon: selectedIcon, color: primaryAccent, size: 32)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(t("PLAN NAME", "НАЗВА ПЛАНУ"))
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.gray)
                                .tracking(1)
                            TextField(t("What is the plan?", "Що це за план?"), text: $name)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .textFieldStyle(.plain)
                        }
                    }

                    if isQuit {
                        QuitConfigurationPanel(
                            selectedMode: $selectedTrackingMode,
                            financialImpact: $financialImpact,
                            financialImpactText: $financialImpactText,
                            selectedCurrency: $selectedCurrency,
                            selectedTimeUnit: $selectedTimeUnit,
                            timeImpactValue: $timeImpactValue,
                            timeImpactText: $timeImpactText,
                            language: appLanguage
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Divider()

                    Picker(t("Icon Style", "Стиль іконки"), selection: $iconCategorySelection) {
                        Text(t("Emoji", "Емодзі")).tag(0)
                        Text(t("Icons", "Іконки")).tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(24)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if iconCategorySelection == 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(t("CUSTOM EMOJI FROM KEYBOARD", "ВЛАСНИЙ ЕМОДЗІ З КЛАВІАТУРИ"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)

                                HStack {
                                    TextField(t("Paste any emoji here...", "Вставте будь-який емодзі сюди..."), text: $userCustomEmoji)
                                        .font(.system(size: 15, weight: .semibold))
                                        .textFieldStyle(.plain)
                                        .onChange(of: userCustomEmoji) { _, newValue in
                                            if let lastChar = newValue.last {
                                                userCustomEmoji = String(lastChar)
                                                selectedIcon = userCustomEmoji
                                            }
                                        }
                                    Spacer()
                                    Text("😀").foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(14)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(14)
                            }
                            .padding(.bottom, 6)

                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                ForEach(emojis, id: \.self) { emoji in
                                    IconChoiceCell(isSelected: selectedIcon == emoji, color: primaryAccent) {
                                        Text(emoji).font(.system(size: 24))
                                    } action: {
                                        selectedIcon = emoji
                                        userCustomEmoji = ""
                                    }
                                }
                            }
                        } else {
                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    IconChoiceCell(isSelected: selectedIcon == icon, color: primaryAccent) {
                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedIcon == icon ? primaryAccent : .gray)
                                    } action: {
                                        selectedIcon = icon
                                        userCustomEmoji = ""
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                Button(action: {
                    onSave(name, selectedIcon, isQuit, selectedTrackingMode, selectedImpactValue)
                    dismiss()
                }) {
                    Text(t("Save to Dashboard", "Зберегти на панель"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(primaryAccent)
                        .cornerRadius(16)
                        .shadow(color: primaryAccent.opacity(0.2), radius: 10, y: 5)
                }
                .padding(24)
                .disabled(name.isEmpty || selectedIcon.isEmpty)
            }
            .navigationTitle(titleLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Close", "Закрити")) { dismiss() }
                }
            }
            .onAppear {
                name = initialName
                selectedIcon = initialIcon
                isQuit = isQuitMode
                selectedTrackingMode = initialTrackingMode
                financialImpact = initialTrackingMode == .financial ? normalizedFinancialImpact(initialImpactValue) : 6
                financialImpactText = formattedFinancialImpact(financialImpact)
                configureInitialTimeImpact(initialTrackingMode == .time ? initialImpactValue : 2)

                if emojis.contains(initialIcon) == false && icons.contains(initialIcon) == false && initialIcon != "⭐️" {
                    userCustomEmoji = initialIcon
                }
            }
        }
    }

    private var primaryAccent: Color {
        isQuit ? selectedTrackingMode.accent : .blue
    }

    private var selectedImpactValue: Double {
        switch selectedTrackingMode {
        case .financial: return financialImpact
        case .time:
            switch selectedTimeUnit {
            case .minutes: return timeImpactValue / 60
            case .hours: return timeImpactValue
            }
        case .pureWillpower: return 0
        }
    }

    private func normalizedFinancialImpact(_ value: Double) -> Double {
        max(0.01, (value * 100).rounded() / 100)
    }

    private func configureInitialTimeImpact(_ hours: Double) {
        let minutes = hours * 60

        if minutes <= 60 {
            selectedTimeUnit = .minutes
            timeImpactValue = min(60, max(1, minutes.rounded()))
            timeImpactText = "\(Int(timeImpactValue.rounded()))"
        } else {
            selectedTimeUnit = .hours
            timeImpactValue = min(24, max(0.5, (hours * 10).rounded() / 10))
            timeImpactText = formattedTimeHours(timeImpactValue)
        }
    }

    private func formattedFinancialImpact(_ value: Double) -> String {
        String(format: "%.2f", normalizedFinancialImpact(value))
    }

    private func formattedTimeHours(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

enum SupportedCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case uah = "UAH"
    case gbp = "GBP"
    case pln = "PLN"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .uah: return "₴"
        case .gbp: return "£"
        case .pln: return "zł"
        }
    }

    var pickerTitle: String {
        "\(rawValue) \(symbol)"
    }
}

enum TimeInputUnit: String, CaseIterable, Identifiable {
    case minutes
    case hours

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .minutes: return language == "ua" ? "Хвилини" : "Minutes"
        case .hours: return language == "ua" ? "Години" : "Hours"
        }
    }
}

struct QuitConfigurationPanel: View {
    @Binding var selectedMode: QuitTrackingMode
    @Binding var financialImpact: Double
    @Binding var financialImpactText: String
    @Binding var selectedCurrency: SupportedCurrency
    @Binding var selectedTimeUnit: TimeInputUnit
    @Binding var timeImpactValue: Double
    @Binding var timeImpactText: String
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language == "ua" ? "РЕЖИМ ВІДНОВЛЕННЯ" : "RECOVERY MODE")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.gray)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(QuitTrackingMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            selectedMode = mode
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 15, weight: .bold))
                            Text(mode.title(language: language))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundColor(selectedMode == mode ? mode.accent : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(selectedMode == mode ? mode.accent.opacity(0.11) : Color.primary.opacity(0.025))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedMode == mode ? mode.accent.opacity(0.35) : Color.primary.opacity(0.04), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            switch selectedMode {
            case .financial:
                FinancialImpactInputCard(
                    title: language == "ua" ? "Щоденні витрати" : "Daily spend",
                    value: $financialImpact,
                    text: $financialImpactText,
                    currency: $selectedCurrency,
                    color: .green
                )
            case .time:
                TimeImpactInputCard(
                    title: language == "ua" ? "Втрачений час щодня" : "Daily time drain",
                    unit: $selectedTimeUnit,
                    value: $timeImpactValue,
                    text: $timeImpactText,
                    language: language,
                    color: .blue
                )
            case .pureWillpower:
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.purple.opacity(0.1)).frame(width: 42, height: 42)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.purple)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language == "ua" ? "Статус сили волі" : "Willpower Status")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text(language == "ua" ? "Без грошей і таймерів. Тільки ясність та контроль." : "No money, no timers. Just clarity and control.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.purple.opacity(0.06))
                .cornerRadius(16)
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.025))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

struct FinancialImpactInputCard: View {
    let title: String
    @Binding var value: Double
    @Binding var text: String
    @Binding var currency: SupportedCurrency
    let color: Color

    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(currency.symbol)\(formatted(value))")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Text(currency.symbol)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(color)
                    TextField("0.50", text: $text)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .textFieldStyle(.plain)
                        .focused($isEditing)
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.primary.opacity(0.035))
                .cornerRadius(13)

                Picker("", selection: $currency) {
                    ForEach(SupportedCurrency.allCases) { currency in
                        Text(currency.pickerTitle).tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .frame(height: 42)
                .padding(.horizontal, 10)
                .background(Color.primary.opacity(0.035))
                .cornerRadius(13)
            }

            Slider(
                value: Binding(
                    get: { min(value, 500) },
                    set: { newValue in
                        value = normalized(newValue)
                        text = formatted(value)
                    }
                ),
                in: 0.01...500,
                step: 0.01
            )
            .tint(color)
        }
        .padding(14)
        .background(color.opacity(0.06))
        .cornerRadius(16)
        .onChange(of: text) { _, newValue in
            syncValue(from: newValue)
        }
        .onChange(of: isEditing) { _, editing in
            if !editing { text = formatted(value) }
        }
        .onChange(of: value) { _, newValue in
            if !isEditing { text = formatted(newValue) }
        }
    }

    private func syncValue(from rawText: String) {
        let normalized = rawText.replacingOccurrences(of: ",", with: ".")
        guard let parsed = Double(normalized) else { return }
        value = self.normalized(parsed)
    }

    private func normalized(_ value: Double) -> Double {
        max(0.01, (value * 100).rounded() / 100)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", normalized(value))
    }
}

struct TimeImpactInputCard: View {
    let title: String
    @Binding var unit: TimeInputUnit
    @Binding var value: Double
    @Binding var text: String
    let language: String
    let color: Color

    @FocusState private var isEditing: Bool
    @State private var isSyncing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text(displayText)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(color)
            }

            Picker("", selection: $unit) {
                ForEach(TimeInputUnit.allCases) { unit in
                    Text(unit.title(language: language)).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                TextField(unit == .minutes ? "45" : "1.5", text: $text)
                    .keyboardType(unit == .minutes ? .numberPad : .decimalPad)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .textFieldStyle(.plain)
                    .focused($isEditing)
                Text(unit == .minutes ? (language == "ua" ? "хв" : "min") : (language == "ua" ? "год" : "h"))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.primary.opacity(0.035))
            .cornerRadius(13)

            Slider(
                value: Binding(
                    get: { value },
                    set: { newValue in
                        value = clamped(newValue, for: unit)
                        text = formattedInput(value, for: unit)
                    }
                ),
                in: sliderRange,
                step: unit == .minutes ? 1 : 0.5
            )
                .tint(color)
        }
        .padding(14)
        .background(color.opacity(0.06))
        .cornerRadius(16)
        .onChange(of: text) { _, newValue in
            guard !isSyncing else { return }
            syncValue(from: newValue)
        }
        .onChange(of: isEditing) { _, editing in
            if !editing { setText(formattedInput(value, for: unit)) }
        }
        .onChange(of: value) { _, newValue in
            if !isEditing { setText(formattedInput(newValue, for: unit)) }
        }
        .onChange(of: unit) { oldUnit, newUnit in
            value = converted(value, from: oldUnit, to: newUnit)
            setText(formattedInput(value, for: newUnit))
        }
    }

    private func syncValue(from rawText: String) {
        let normalized = rawText.replacingOccurrences(of: ",", with: ".")

        if unit == .minutes {
            let digits = normalized.filter(\.isNumber)
            if digits != normalized {
                setText(digits)
                return
            }
            guard let parsed = Double(digits) else { return }

            if parsed > 60 {
                unit = .hours
                value = clamped(parsed / 60, for: .hours)
                setText(formattedInput(value, for: .hours))
            } else {
                value = clamped(parsed, for: .minutes)
            }
            return
        }

        guard let parsed = Double(normalized) else { return }
        value = clamped(parsed, for: .hours)
    }

    private var sliderRange: ClosedRange<Double> {
        unit == .minutes ? 1...60 : 0.5...24
    }

    private var displayText: String {
        switch unit {
        case .minutes:
            return "\(Int(value.rounded())) m"
        case .hours:
            return formattedHours(value)
        }
    }

    private func clamped(_ value: Double, for unit: TimeInputUnit) -> Double {
        switch unit {
        case .minutes:
            return min(60, max(1, value.rounded()))
        case .hours:
            return min(24, max(0.5, (value * 10).rounded() / 10))
        }
    }

    private func converted(_ value: Double, from oldUnit: TimeInputUnit, to newUnit: TimeInputUnit) -> Double {
        guard oldUnit != newUnit else { return clamped(value, for: newUnit) }

        switch (oldUnit, newUnit) {
        case (.minutes, .hours):
            return clamped(value / 60, for: .hours)
        case (.hours, .minutes):
            return clamped(value * 60, for: .minutes)
        default:
            return clamped(value, for: newUnit)
        }
    }

    private func formattedInput(_ value: Double, for unit: TimeInputUnit) -> String {
        switch unit {
        case .minutes:
            return "\(Int(value.rounded()))"
        case .hours:
            return value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
        }
    }

    private func formattedHours(_ value: Double) -> String {
        let wholeHours = Int(value)
        let minutes = Int(((value - Double(wholeHours)) * 60).rounded())

        if minutes == 0 {
            return "\(wholeHours) h"
        }

        if wholeHours == 0 {
            return "\(minutes) m"
        }

        return "\(wholeHours) h \(minutes) m"
    }

    private func setText(_ newText: String) {
        guard text != newText else { return }
        isSyncing = true
        text = newText
        isSyncing = false
    }
}

struct IconChoiceCell<Content: View>: View {
    let isSelected: Bool
    let color: Color
    @ViewBuilder let content: Content
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? color.opacity(0.15) : Color.primary.opacity(0.03))
                    .frame(height: 52)
                content
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HabitIconView: View {
    let icon: String
    let color: Color
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            if isSystemSymbol(icon) {
                Image(systemName: icon)
                    .font(.system(size: size == 32 ? 24 : 18, weight: .medium))
                    .foregroundColor(color)
            } else {
                Text(icon)
                    .font(.system(size: size))
            }
        }
        .frame(width: 32)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.gray.opacity(0.8))
                .tracking(1)
                .textCase(.uppercase)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .textCase(nil)
            }
        }
    }
}

private func localizedPlanName(_ name: String, language: String) -> String {
    guard language == "ua" else {
        switch name {
        case "Тренування в залі": return "Gym Workout"
        case "Здоровий сон": return "Healthy Sleep"
        case "Пити воду": return "Hydrate"
        case "Кинути палити": return "Quit Smoking"
        case "Менше TikTok": return "No TikTok Scrolling"
        case "Без алкоголю": return "No Alcohol"
        default: return name
        }
    }

    switch name {
    case "Gym Workout": return "Тренування в залі"
    case "Healthy Sleep": return "Здоровий сон"
    case "Hydrate": return "Пити воду"
    case "Quit Smoking": return "Кинути палити"
    case "No TikTok Scrolling": return "Менше TikTok"
    case "No Alcohol": return "Без алкоголю"
    default: return name
    }
}

private func isSystemSymbol(_ value: String) -> Bool {
    value.rangeOfCharacter(from: CharacterSet.letters) != nil
}

private func healingScore(for challenge: AdvancedQuitItem) -> Double {
    let clean = Double(challenge.cleanDays)
    let relapsed = Double(challenge.relapseDays)
    let consecutive = Double(challenge.consecutiveCleanDays())
    let score = (clean * 7.0) + (consecutive * 3.0) - (relapsed * 8.0)
    return min(100, max(0, score))
}

private func milestoneFor(days: Int, language: String) -> String {
    if days >= 30 {
        return language == "ua" ? "Повністю зцілений Shram" : "Fully Healed Shram"
    } else if days >= 14 {
        return language == "ua" ? "Тканина відновлюється" : "Tissue Regenerating"
    } else if days >= 7 {
        return language == "ua" ? "Свербіж зник" : "Craving Fading"
    } else if days >= 3 {
        return language == "ua" ? "Рана закрита" : "Wound Sealed"
    } else if days >= 1 {
        return language == "ua" ? "Перший чистий день" : "First Clean Day"
    } else {
        return language == "ua" ? "Позначте день, щоб почати" : "Mark a day to begin"
    }
}

private func formattedHours(_ value: Double, language: String) -> String {
    if value.rounded() == value {
        return language == "ua" ? "\(Int(value)) год" : "\(Int(value))h"
    }
    return language == "ua" ? String(format: "%.1f год", value) : String(format: "%.1fh", value)
}
