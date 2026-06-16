import SwiftUI

enum PlannerTaskType: String, Codable, CaseIterable {
    case specificDay
    case deadline
    
    var title: String {
        switch self {
        case .specificDay: return "Specific Day"
        case .deadline: return "Deadline"
        }
    }
    
    var icon: String {
        switch self {
        case .specificDay: return "calendar"
        case .deadline: return "flag.fill"
        }
    }
}

enum PlannerTaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .red
        }
    }
}

struct PlannerTask: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var taskType: PlannerTaskType
    var priority: PlannerTaskPriority

    init(id: UUID = UUID(), title: String, dueDate: Date, isCompleted: Bool = false, taskType: PlannerTaskType = .specificDay, priority: PlannerTaskPriority = .medium) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.taskType = taskType
        self.priority = priority
    }
}

struct PlannerView: View {
    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var editingTask: PlannerTask?
    @State private var tasks: [PlannerTask] = []
    @State private var toggledTaskIDs: Set<UUID> = []

    private let calendar = Calendar.current

    private var tasksForSelectedDate: [PlannerTask] {
        tasks.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }.sorted(by: taskSort)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Planner")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Organize your days. Map out your goals.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 4)
                .padding(.top, 16)

                calendarDashboard
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(
            ZStack {
                Color(uiColor: .systemBackground)
                LinearGradient(
                    colors: [Color.primary.opacity(0.012), Color.primary.opacity(0.006)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .safeAreaInset(edge: .bottom) {
            newTaskButton
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showAddTask) {
            AddFlexibleTaskView(baseDate: selectedDate) { task in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    tasks.insert(task, at: 0)
                }
            }
        }
        .sheet(item: $editingTask) { task in
            AddFlexibleTaskView(taskToEdit: task, baseDate: task.dueDate) { updated in
                if let index = tasks.firstIndex(where: { $0.id == updated.id }) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                        tasks[index] = updated
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var calendarDashboard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Calendar Grid")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Spacer()
                Text(selectedDate, style: .date)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            WeeklyCalendarStrip(selectedDate: $selectedDate, tasks: tasks)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    MonthDayCell(date: date, selectedDate: selectedDate, tasks: tasksFor(date)) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            selectedDate = date
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Day")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                if tasksForSelectedDate.isEmpty {
                    EmptyPlannerCard(text: "Clear space. No tasks assigned for this day.")
                        .frame(minHeight: 132)
                } else {
                    ForEach(tasksForSelectedDate) { task in
                        PlannerTaskRow(task: task, isAnimating: toggledTaskIDs.contains(task.id)) {
                            toggle(task)
                        }
                        .taskInteractions(task: task, edit: { editingTask = task }, delete: { delete(task) })
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
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("New Task")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 5)
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
        return lhs.dueDate < rhs.dueDate
    }

    private func toggle(_ task: PlannerTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.58)) {
            tasks[index].isCompleted.toggle()
            toggledTaskIDs.insert(task.id)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
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
                            .fill(taskCount(for: date) > 0 ? (isSelected ? Color.white : Color.blue) : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? Color.blue : Color.primary.opacity(0.03))
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
        let labels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        return labels[index]
    }
}

struct MonthDayCell: View {
    let date: Date
    let selectedDate: Date
    let tasks: [PlannerTask]
    var action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(isSelected ? .white : isCurrentMonth ? .primary : .secondary.opacity(0.45))
                Circle()
                    .fill(tasks.isEmpty ? Color.clear : Color.blue)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isSelected ? Color.blue : Color.primary.opacity(0.025))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select day")
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
                .foregroundColor(.blue.opacity(0.62))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.blue.opacity(0.06)))
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

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: task.taskType.icon)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 5, height: 5)
                    
                    Text(task.priority.title)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(task.dueDate, style: .time)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(14)
        .plannerGlassCard(cornerRadius: 20)
    }
}

struct AddFlexibleTaskView: View {
    @Environment(\.dismiss) private var dismiss

    var taskToEdit: PlannerTask?
    var baseDate: Date
    var onSave: (PlannerTask) -> Void

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var taskType: PlannerTaskType = .specificDay
    @State private var priority: PlannerTaskPriority = .medium

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(taskToEdit == nil ? "New Task" : "Edit Task")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Schedule and prioritize your upcoming work.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 16)

                    titleInput
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TASK TYPE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            ForEach(PlannerTaskType.allCases, id: \.self) { type in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        taskType = type
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(taskType == type ? .blue : .secondary)
                                        
                                        Text(type.title)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundColor(taskType == type ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(taskType == type ? Color.blue.opacity(0.08) : Color.primary.opacity(0.02))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(taskType == type ? Color.blue.opacity(0.2) : Color.primary.opacity(0.04), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("IMPORTANCE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)
                        
                        HStack(spacing: 10) {
                            ForEach(PlannerTaskPriority.allCases, id: \.self) { prio in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        priority = prio
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(prio.color)
                                            .frame(width: 6, height: 6)
                                        
                                        Text(prio.title)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundColor(priority == prio ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(priority == prio ? prio.color.opacity(0.08) : Color.primary.opacity(0.02))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(priority == prio ? prio.color.opacity(0.2) : Color.primary.opacity(0.04), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("SCHEDULE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)
                        
                        DatePicker("Date and Time", selection: $dueDate)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(16)
                            .background(Color.primary.opacity(0.02))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save to Planner")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 5)
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
                    taskType = taskToEdit.taskType
                    priority = taskToEdit.priority
                } else {
                    dueDate = baseDate
                }
            }
        }
    }

    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TITLE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.5)
                .padding(.leading, 4)
            TextField(
                "",
                text: $title,
                prompt: Text("What needs to happen?")
                    .foregroundColor(.secondary)
            )
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .textFieldStyle(.plain)
            .padding(16)
            .background(Color.primary.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private func save() {
        let task = PlannerTask(
            id: taskToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            isCompleted: taskToEdit?.isCompleted ?? false,
            taskType: taskType,
            priority: priority
        )
        onSave(task)
        dismiss()
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

    func taskInteractions(task: PlannerTask, edit: @escaping () -> Void, delete: @escaping () -> Void) -> some View {
        self
            .contextMenu {
                Button(action: edit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: delete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                Button(action: edit) {
                    Image(systemName: "pencil")
                }
                .tint(.blue)
            }
    }
}

#Preview {
    NavigationStack {
        PlannerView()
    }
}
