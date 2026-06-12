import SwiftUI
import Charts

enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case high
    case medium
    case low

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .high: return language == "ua" ? "Високий" : "High"
        case .medium: return language == "ua" ? "Середній" : "Medium"
        case .low: return language == "ua" ? "Низький" : "Low"
        }
    }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }

    var rank: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

enum EnergyCost: String, CaseIterable, Identifiable, Codable {
    case highFocus
    case quickWin
    case routine

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .highFocus: return language == "ua" ? "🧠 Глибокий фокус" : "🧠 High Focus"
        case .quickWin: return language == "ua" ? "⚡️ Швидка перемога" : "⚡️ Quick Win"
        case .routine: return language == "ua" ? "☕️ Рутина" : "☕️ Routine"
        }
    }

    var icon: String {
        switch self {
        case .highFocus: return "brain.head.profile"
        case .quickWin: return "bolt.fill"
        case .routine: return "cup.and.saucer.fill"
        }
    }

    var color: Color {
        switch self {
        case .highFocus: return .purple
        case .quickWin: return .yellow
        case .routine: return .brown
        }
    }
}

struct PlannerTask: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: TaskPriority
    var energyCost: EnergyCost

    init(id: UUID = UUID(), title: String, dueDate: Date, isCompleted: Bool = false, priority: TaskPriority, energyCost: EnergyCost) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.energyCost = energyCost
    }
}

struct PlannerChartSlice: Identifiable {
    let id: String
    let title: String
    let count: Int
    let color: Color
}

struct PlannerView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var editingTask: PlannerTask?
    @State private var tasks: [PlannerTask] = []
    @State private var toggledTaskIDs: Set<UUID> = []

    private let calendar = Calendar.current

    private func t(_ english: String, _ ukrainian: String) -> String {
        appLanguage == "ua" ? ukrainian : english
    }

    private var tasksForSelectedDate: [PlannerTask] {
        tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }.sorted(by: taskSort)
    }

    private var chartSlices: [PlannerChartSlice] {
        let completed = tasksForSelectedDate.filter(\.isCompleted).count
        let pending = tasksForSelectedDate.count - completed
        return [
            PlannerChartSlice(id: "completed", title: t("Completed", "Виконано"), count: completed, color: .primary),
            PlannerChartSlice(id: "pending", title: t("Pending", "Очікує"), count: pending, color: .secondary.opacity(0.32))
        ].filter { $0.count > 0 }
    }

    private var completionRate: Int {
        guard !tasksForSelectedDate.isEmpty else { return 0 }
        let done = tasksForSelectedDate.filter(\.isCompleted).count
        return Int((Double(done) / Double(tasksForSelectedDate.count) * 100).rounded())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    efficiencyCore
                    calendarDashboard
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 104)
            }
            .background(
                LinearGradient(
                    colors: [Color.primary.opacity(0.012), Color.primary.opacity(0.006)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            newTaskButton
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
        .sheet(isPresented: $showAddTask) {
            AddFlexibleTaskView(language: appLanguage, baseDate: selectedDate) { task in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    tasks.insert(task, at: 0)
                }
            }
        }
        .sheet(item: $editingTask) { task in
            AddFlexibleTaskView(language: appLanguage, taskToEdit: task, baseDate: task.dueDate) { updated in
                if let index = tasks.firstIndex(where: { $0.id == updated.id }) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                        tasks[index] = updated
                    }
                }
            }
        }
    }

    private var efficiencyCore: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("Efficiency Core", "Ядро ефективності"))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                    Text(t("A zero baseline for intentional planning", "Нульова база для усвідомленого планування"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(completionRate)%")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 18) {
                ZStack {
                    if chartSlices.isEmpty {
                        Circle()
                            .stroke(Color.primary.opacity(0.05), lineWidth: 16)
                            .frame(width: 142, height: 142)
                    } else {
                        Chart(chartSlices) { slice in
                            SectorMark(
                                angle: .value(t("Tasks", "Завдання"), slice.count),
                                innerRadius: .ratio(0.62),
                                outerRadius: .inset(4),
                                angularInset: 1.6
                            )
                            .cornerRadius(5)
                            .foregroundStyle(slice.color)
                        }
                        .chartLegend(.hidden)
                        .frame(width: 142, height: 142)
                    }

                    VStack(spacing: 2) {
                        Text("\(tasksForSelectedDate.count)")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                        Text(t("tasks", "завд."))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(chartSlices) { slice in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 9, height: 9)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(slice.color.opacity(0.08)))
                            Text(slice.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                            Text("\(slice.count)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }

                    if chartSlices.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.primary.opacity(0.04)))
                            Text(t("No tasks", "Немає завдань"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                            Text("0")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(18)
        .plannerGlassCard(cornerRadius: 24)
    }

    private var calendarDashboard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(t("Calendar Grid", "Календарна сітка"))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Spacer()
                Text(selectedDate, style: .date)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            WeeklyCalendarStrip(selectedDate: $selectedDate, tasks: tasks, language: appLanguage)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    MonthDayCell(date: date, selectedDate: selectedDate, tasks: tasksFor(date), language: appLanguage) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            selectedDate = date
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(t("Selected Day", "Обраний день"))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                if tasksForSelectedDate.isEmpty {
                    EmptyPlannerCard(text: t("Clear space. No tasks assigned for this day.", "Чистий простір. На цей день завдань немає."))
                        .frame(minHeight: 132)
                } else {
                    ForEach(tasksForSelectedDate) { task in
                        PlannerTaskRow(task: task, language: appLanguage, isAnimating: toggledTaskIDs.contains(task.id)) {
                            toggle(task)
                        }
                        .taskInteractions(task: task, language: appLanguage, edit: { editingTask = task }, delete: { delete(task) })
                    }
                }
            }
        }
        .padding(18)
        .plannerGlassCard(cornerRadius: 24)
    }

    private var newTaskButton: some View {
        Button {
            showAddTask = true
        } label: {
            HStack(spacing: 10) {
                Text("＋")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                Text(t("New Task", "Нове завдання"))
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundColor(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(Color.primary)
                    .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var monthDates: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthRange = calendar.range(of: .day, in: .month, for: selectedDate) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingEmptyDays = (firstWeekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -leadingEmptyDays, to: interval.start) ?? interval.start
        return (0..<(monthRange.count + leadingEmptyDays)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func tasksFor(_ date: Date) -> [PlannerTask] {
        tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    private func taskSort(_ lhs: PlannerTask, _ rhs: PlannerTask) -> Bool {
        if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
        if lhs.priority.rank != rhs.priority.rank { return lhs.priority.rank < rhs.priority.rank }
        return lhs.dueDate < rhs.dueDate
    }

    private func toggle(_ task: PlannerTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.58)) {
            tasks[index].isCompleted.toggle()
            toggledTaskIDs.insert(task.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                _ = toggledTaskIDs.remove(task.id)
            }
        }
    }

    private func delete(_ task: PlannerTask) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            tasks.removeAll { $0.id == task.id }
        }
    }
}

struct WeeklyCalendarStrip: View {
    @Binding var selectedDate: Date
    let tasks: [PlannerTask]
    let language: String

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 7) {
                        Text(weekdayLabel(for: date))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(isSelected ? .white : .primary)
                        Circle()
                            .fill(taskCount(for: date) > 0 ? (isSelected ? Color.white : Color.orange) : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? Color.orange : Color.primary.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(isSelected ? 0 : 0.05), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weekDates: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func taskCount(for date: Date) -> Int {
        tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: date) }.count
    }

    private func weekdayLabel(for date: Date) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        let english = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        let ukrainian = ["Нд", "Пн", "Вв", "Ср", "Чт", "Пт", "Сб"]
        return language == "ua" ? ukrainian[index] : english[index]
    }
}

struct MonthDayCell: View {
    let date: Date
    let selectedDate: Date
    let tasks: [PlannerTask]
    let language: String
    var action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(isSelected ? .white : isCurrentMonth ? .primary : .secondary.opacity(0.45))
                HStack(spacing: 2) {
                    ForEach(tasks.prefix(3)) { task in
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 5)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isSelected ? Color.orange : Color.primary.opacity(0.025))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language == "ua" ? "Обрати день" : "Select day")
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
    }
}

struct EmptyPlannerCard: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.orange.opacity(0.62))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.orange.opacity(0.06)))
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color.primary.opacity(0.018))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.035), lineWidth: 1)
        )
    }
}

struct PlannerTaskRow: View {
    let task: PlannerTask
    let language: String
    let isAnimating: Bool
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? Color.green : Color.primary.opacity(0.035))
                        .frame(width: 34, height: 34)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(task.isCompleted ? .white : .clear)
                }
                .overlay(Circle().stroke(task.isCompleted ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1.2))
                .scaleEffect(isAnimating ? 1.18 : 1)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    PlannerPill(text: task.priority.title(language: language), color: task.priority.color)
                    PlannerPill(text: task.energyCost.title(language: language), color: task.energyCost.color)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(task.dueDate, style: .time)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Image(systemName: task.energyCost.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(task.energyCost.color)
            }
        }
        .padding(14)
        .plannerGlassCard(cornerRadius: 20)
    }
}

struct PlannerPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.66)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.075))
            .clipShape(Capsule())
    }
}

struct AddFlexibleTaskView: View {
    @Environment(\.dismiss) private var dismiss

    let language: String
    var taskToEdit: PlannerTask?
    var baseDate: Date
    var onSave: (PlannerTask) -> Void

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority: TaskPriority = .medium
    @State private var energyCost: EnergyCost = .quickWin

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    titleInput
                    DatePicker(language == "ua" ? "Дата і час" : "Date and Time", selection: $dueDate)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .padding(16)
                        .plannerGlassCard(cornerRadius: 18)

                    selectorSection(title: language == "ua" ? "Пріоритет" : "Priority") {
                        HStack(spacing: 8) {
                            ForEach(TaskPriority.allCases) { item in
                                SelectionChip(title: item.title(language: language), icon: "flag.fill", color: item.color, isSelected: priority == item) {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { priority = item }
                                }
                            }
                        }
                    }

                    selectorSection(title: language == "ua" ? "Вартість енергії" : "Energy Cost") {
                        VStack(spacing: 8) {
                            ForEach(EnergyCost.allCases) { item in
                                SelectionWideChip(title: item.title(language: language), icon: item.icon, color: item.color, isSelected: energyCost == item) {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { energyCost = item }
                                }
                            }
                        }
                    }

                }
                .padding(20)
            }
            .navigationTitle(taskToEdit == nil ? (language == "ua" ? "Нове завдання" : "New Task") : (language == "ua" ? "Редагувати" : "Edit Task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == "ua" ? "Скасувати" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language == "ua" ? "Зберегти" : "Save") { save() }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text(language == "ua" ? "Зберегти" : "Save to Planner")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.primary)
                        .cornerRadius(18)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .onAppear {
                if let taskToEdit {
                    title = taskToEdit.title
                    dueDate = taskToEdit.dueDate
                    priority = taskToEdit.priority
                    energyCost = taskToEdit.energyCost
                } else {
                    dueDate = baseDate
                }
            }
        }
    }

    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(language == "ua" ? "НАЗВА" : "TITLE")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.2)
            TextField(language == "ua" ? "Що потрібно зробити?" : "What needs to happen?", text: $title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .textFieldStyle(.plain)
        }
        .padding(16)
        .plannerGlassCard(cornerRadius: 18)
    }

    private func selectorSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.2)
            content()
        }
        .padding(16)
        .plannerGlassCard(cornerRadius: 18)
    }

    private func save() {
        let task = PlannerTask(
            id: taskToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            isCompleted: taskToEdit?.isCompleted ?? false,
            priority: priority,
            energyCost: energyCost
        )
        onSave(task)
        dismiss()
    }
}

struct SelectionChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(isSelected ? color : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(isSelected ? color.opacity(0.11) : Color.primary.opacity(0.025))
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? color.opacity(0.35) : Color.primary.opacity(0.04), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct SelectionWideChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(color.opacity(0.09)))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(isSelected ? color : .secondary)
            .padding(12)
            .background(isSelected ? color.opacity(0.1) : Color.primary.opacity(0.025))
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? color.opacity(0.32) : Color.primary.opacity(0.04), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func plannerGlassCard(cornerRadius: CGFloat) -> some View {
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

    func taskInteractions(task: PlannerTask, language: String, edit: @escaping () -> Void, delete: @escaping () -> Void) -> some View {
        self
            .contextMenu {
                Button(action: edit) {
                    Label(language == "ua" ? "Редагувати" : "Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: delete) {
                    Label(language == "ua" ? "Видалити" : "Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                Button(action: edit) {
                    Image(systemName: "pencil")
                }
                .tint(.orange)
            }
    }
}

#Preview {
    NavigationStack {
        PlannerView()
    }
}
