import SwiftUI
import PhotosUI

struct CategoryDetailView: View {
    let categoryId: CategoryId
    var initialStat: CategoryStat?

    @State private var stat: CategoryStat?
    @State private var isCompleting = false
    @State private var reward: CompleteTaskResult?
    @State private var errorMessage: String?

    // Focus timer
    private let focusTimer = FocusTimerManager.shared
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Fitness photo
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isUploading = false

    // Screen discipline
    private let sdManager = ScreenDisciplineManager.shared
    @State private var isEditingGoal = false
    @State private var editGoalHours = 3
    @State private var editGoalMins = 0
    @State private var checkInHours = 0
    @State private var checkInMins = 0

    private var isCompletedToday: Bool {
        guard let last = stat?.lastCompletedDate else { return false }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")!
        return last == f.string(from: cal.startOfDay(for: Date()))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                heroSection
                if let s = stat {
                    statsRow(s)
                }
                if categoryId == .fitness {
                    fitnessPhotoCard
                    fitnessSubmitCTA
                } else if categoryId == .focus {
                    focusTimerCard
                    focusSubmitCTA
                } else if categoryId == .screenDiscipline {
                    screenGoalCard
                    screenCheckInSection
                } else {
                    promptCard
                    ctaSection
                }
            }
            .padding(.bottom, 36)
        }
        .lmBackground()
        .navigationTitle(categoryId.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            stat = initialStat
            if let fresh = try? await ProfileAPI.shared.getCategories()
                .first(where: { $0.categoryId == categoryId }) {
                stat = fresh
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                selectedPhotoData = try? await item?.loadTransferable(type: Data.self)
            }
        }
        .onAppear {
            guard categoryId == .focus else { return }
            focusTimer.tick()
        }
        .onReceive(ticker) { _ in
            guard categoryId == .focus else { return }
            focusTimer.tick()
        }
        .overlay {
            if let r = reward {
                XPRewardOverlay(result: r)
                    .onTapGesture { reward = nil }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let err = errorMessage {
                ErrorBanner(message: err)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(categoryId.color)

            Image(systemName: categoryId.systemImageName)
                .font(.system(size: 140, weight: .black))
                .foregroundStyle(.black.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.45))
                        .frame(width: 56, height: 56)
                    Image(systemName: categoryId.systemImageName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                }
                Text(categoryId.displayName)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            .padding(24)
        }
        .frame(height: 210)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Stats

    private func statsRow(_ s: CategoryStat) -> some View {
        HStack(spacing: 12) {
            statTile(value: "\(s.currentStreak)", label: "Streak", icon: "flame.fill", iconColor: .orange)
            statTile(value: "\(s.longestStreak)", label: "Best", icon: "trophy.fill", iconColor: Color(hex: "E6A800"))
            statTile(
                value: isCompletedToday ? "Done" : "–",
                label: "Today",
                icon: isCompletedToday ? "checkmark.circle.fill" : "circle",
                iconColor: isCompletedToday ? Theme.accentGreen : Theme.textSecondary
            )
        }
        .padding(.horizontal, 20)
    }

    private func statTile(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Prompt (non-special categories)

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Challenge")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(categoryId.questPrompt)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
    }

    // MARK: - CTA (non-special categories)

    private var ctaSection: some View {
        Group {
            if isCompletedToday {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accentGreen)
                    Text("Completed for today — great work!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            } else {
                Button {
                    Task { await complete() }
                } label: {
                    if isCompleting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Mark as Done Today")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isCompleting)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Fitness: Photo Card

    private var fitnessPhotoCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Gym Photo")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if selectedPhotoData != nil {
                    Button("Retake") {
                        selectedPhotoItem = nil
                        selectedPhotoData = nil
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                }
            }

            if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text("Choose a Gym Photo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text("Show your workout or a pump pic — your friends will see it!")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
    }

    // MARK: - Fitness: Submit CTA

    private var fitnessSubmitCTA: some View {
        Group {
            if isCompletedToday {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accentGreen)
                    Text("Workout logged for today — nice work!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            } else {
                Button {
                    Task { await submitWorkout() }
                } label: {
                    if isUploading || isCompleting {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text(isUploading ? "Uploading Photo…" : "Logging Workout…")
                        }
                    } else {
                        Text("Log Workout")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isUploading || isCompleting || selectedPhotoData == nil)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Focus: Timer Card

    private var focusTimerCard: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                Text("Study Timer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if focusTimer.isRunning {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(.red)
                            .frame(width: 7, height: 7)
                            .phaseAnimator([1.0, 0.3]) { dot, opacity in
                                dot.opacity(opacity)
                            } animation: { _ in .easeInOut(duration: 0.7) }
                        Text("Recording")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }
            }

            Text(focusTimer.formatted(focusTimer.displaySeconds))
                .font(.system(size: 56, weight: .black, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.15), value: Int(focusTimer.displaySeconds))
                .frame(maxWidth: .infinity)

            if !isCompletedToday && !focusTimer.isSubmittedToday {
                Button {
                    focusTimer.toggleTimer()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: focusTimer.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(focusTimer.isRunning ? "Pause" : (focusTimer.hasTime ? "Resume" : "Start Session"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .animation(.spring(duration: 0.25), value: focusTimer.isRunning)
            }

            if !focusTimer.hasTime && !isCompletedToday && !focusTimer.isSubmittedToday {
                Text("Stay in the app to keep the timer running. Leaving pauses it.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
    }

    // MARK: - Focus: Submit CTA

    private var focusSubmitCTA: some View {
        Group {
            if isCompletedToday || focusTimer.isSubmittedToday {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accentGreen)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Session submitted — great work!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if focusTimer.accumulatedSeconds > 0 {
                            Text("\(focusTimer.formatted(focusTimer.accumulatedSeconds)) logged today")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(20)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 8) {
                    Button {
                        Task { await submitFocusSession() }
                    } label: {
                        if isCompleting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit Session")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isCompleting || !focusTimer.hasTime)
                    .padding(.horizontal, 20)

                    if !focusTimer.hasTime {
                        Text("Start a session above to log your study time")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Screen Discipline: Goal Card

    private var screenGoalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditingGoal {
                Text("Set Daily Goal")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text("Aim to stay under this much screen time:")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 0) {
                    Picker("Hours", selection: $editGoalHours) {
                        ForEach(0..<13) { Text("\($0)h").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Minutes", selection: $editGoalMins) {
                        ForEach(0..<60) { Text("\($0)m").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 120)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        withAnimation(.spring(duration: 0.3)) { isEditingGoal = false }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button("Save Goal") {
                        sdManager.setGoal(editGoalHours * 60 + editGoalMins)
                        withAnimation(.spring(duration: 0.3)) { isEditingGoal = false }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(editGoalHours == 0 && editGoalMins == 0)
                }
            } else {
                HStack {
                    Text("Daily Goal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                    if !sdManager.isSubmittedToday && !isCompletedToday {
                        Button("Edit") {
                            editGoalHours = sdManager.goalMinutes / 60
                            editGoalMins = sdManager.goalMinutes % 60
                            withAnimation(.spring(duration: 0.3)) { isEditingGoal = true }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    }
                }

                Text("≤ \(formatMinutes(sdManager.goalMinutes)) per day")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text("Open Settings → Screen Time → See All Activity to find today's total.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
        .animation(.spring(duration: 0.3), value: isEditingGoal)
    }

    // MARK: - Screen Discipline: Check-In Section

    private var screenCheckInSection: some View {
        Group {
            if isCompletedToday || sdManager.isSubmittedToday {
                let met = sdManager.metGoalToday
                HStack(spacing: 12) {
                    Image(systemName: met == false ? "arrow.up.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(met == false ? Color.orange : Theme.accentGreen)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(met == false
                             ? "Over today — keep working at it."
                             : "Under your goal — great job!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if let mins = sdManager.todayMinutes {
                            Text("\(formatMinutes(mins)) used vs ≤ \(formatMinutes(sdManager.goalMinutes)) goal")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(20)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Check-In")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text("How much screen time did you log today?")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textPrimary)

                        HStack(spacing: 0) {
                            Picker("Hours", selection: $checkInHours) {
                                ForEach(0..<13) { Text("\($0)h").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)

                            Picker("Minutes", selection: $checkInMins) {
                                ForEach(0..<60) { Text("\($0)m").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)

                    Button {
                        Task { await submitScreenTime() }
                    } label: {
                        if isCompleting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit Check-In")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isCompleting || (checkInHours == 0 && checkInMins == 0))
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ total: Int) -> String {
        let h = total / 60, m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: - Actions

    private func complete() async {
        isCompleting = true
        errorMessage = nil
        defer { isCompleting = false }
        do {
            reward = try await TasksAPI.shared.completeTask(categoryId: categoryId)
            if let fresh = try? await ProfileAPI.shared.getCategories()
                .first(where: { $0.categoryId == categoryId }) {
                stat = fresh
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitFocusSession() async {
        isCompleting = true
        errorMessage = nil
        defer { isCompleting = false }
        do {
            reward = try await TasksAPI.shared.completeTask(categoryId: categoryId)
            focusTimer.markSubmitted()
            if let fresh = try? await ProfileAPI.shared.getCategories()
                .first(where: { $0.categoryId == categoryId }) {
                stat = fresh
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitWorkout() async {
        guard let photoData = selectedPhotoData else { return }
        errorMessage = nil

        do {
            isUploading = true
            let urlResponse = try await FeedAPI.shared.getUploadUrl()
            // Compress to JPEG before upload
            let jpeg = UIImage(data: photoData)?.jpegData(compressionQuality: 0.7) ?? photoData
            try await FeedAPI.shared.uploadPhoto(jpeg, to: urlResponse.uploadUrl)
            isUploading = false

            isCompleting = true
            reward = try await TasksAPI.shared.completeTask(categoryId: categoryId, photoS3Key: urlResponse.s3Key)
            if let fresh = try? await ProfileAPI.shared.getCategories()
                .first(where: { $0.categoryId == categoryId }) {
                stat = fresh
            }
        } catch {
            isUploading = false
            isCompleting = false
            errorMessage = error.localizedDescription
        }
        isCompleting = false
    }

    private func submitScreenTime() async {
        isCompleting = true
        errorMessage = nil
        defer { isCompleting = false }
        do {
            reward = try await TasksAPI.shared.completeTask(categoryId: categoryId)
            sdManager.submitToday(checkInHours * 60 + checkInMins)
            if let fresh = try? await ProfileAPI.shared.getCategories()
                .first(where: { $0.categoryId == categoryId }) {
                stat = fresh
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
