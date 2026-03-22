import SwiftUI
import SwiftData
import TimerCore

// MARK: - Daily Task View

struct DailyTaskView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyTask.createdAt) private var allTasks: [DailyTask]

    private var todayTasks: [TaskItem] {
        let items = allTasks.map(\.asTaskItem)
        return TaskEngine.todayTasks(items)
    }

    private var sortedTasks: [TaskItem] {
        TaskEngine.sorted(todayTasks)
    }

    private var completionRate: Double {
        TaskEngine.completionRate(todayTasks)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("tasks.title", bundle: lang.bundle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                if !todayTasks.isEmpty {
                    Text("\(todayTasks.filter(\.isCompleted).count)/\(todayTasks.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 8)

            // Completion progress bar
            if !todayTasks.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(theme.accentColor)
                            .frame(width: geo.size.width * completionRate, height: 3)
                            .animation(.easeInOut(duration: 0.3), value: completionRate)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }

            // Input field
            TaskInputField(allTasks: allTasks) { title in
                let task = DailyTask(title: title)
                modelContext.insert(task)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.06))

            // Task list
            if sortedTasks.isEmpty {
                VStack(spacing: 6) {
                    Text("tasks.empty", bundle: lang.bundle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.25))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedTasks) { item in
                            TaskRowView(item: item) {
                                toggleTask(id: item.id)
                            }
                            Divider()
                                .background(Color.white.opacity(0.04))
                                .padding(.leading, 40)
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
    }

    private func toggleTask(id: UUID) {
        guard let task = allTasks.first(where: { $0.id == id }) else { return }
        task.toggleCompletion()
    }
}

// MARK: - Task Input Field

private struct TaskInputField: View {
    let allTasks: [DailyTask]
    let onSubmit: (String) -> Void

    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var theme: ThemeManager
    @State private var input = ""
    @State private var showSuggestions = false

    private var suggestions: [String] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let recentTitles = allTasks
            .filter { $0.createdAt >= cutoff }
            .map(\.title)
        return TaskEngine.autocompleteSuggestions(input: input, from: recentTitles)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))

                TextField(lang.loc("tasks.input.placeholder"), text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .onSubmit { submitTask() }
                    .onChange(of: input) { _, newValue in
                        showSuggestions = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .glassRoundedRect(cornerRadius: 8, fallback: Color.white.opacity(0.05))

            if showSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            input = suggestion
                            showSuggestions = false
                            submitTask()
                        } label: {
                            HStack {
                                Text(verbatim: suggestion)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                Spacer()
                                Text("Tab ↹")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.15))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .glassRoundedRect(cornerRadius: 6, fallback: Color.white.opacity(0.04))
                .padding(.top, 2)
            }
        }
    }

    private func submitTask() {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        input = ""
        showSuggestions = false
    }
}

// MARK: - Task Row

private struct TaskRowView: View {
    let item: TaskItem
    let onToggle: () -> Void

    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(item.isCompleted ? theme.accentColor : .white.opacity(0.2))

                Text(verbatim: item.title)
                    .font(.system(size: 12))
                    .foregroundColor(item.isCompleted ? .white.opacity(0.25) : .white.opacity(0.7))
                    .strikethrough(item.isCompleted, color: .white.opacity(0.15))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
