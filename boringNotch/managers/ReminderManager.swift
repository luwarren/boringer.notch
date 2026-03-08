//
//  ReminderManager.swift
//  boringNotch
//
//  Created by Warren Lu on 08/03/2026.
//

import Foundation
import Defaults
import Combine
import SwiftUI

@MainActor
final class ReminderManager: ObservableObject {
    static let shared = ReminderManager()

    @Published var showReminder: Bool = false
    @Published var nextTrigger: Date?
    @Published var countdown: TimeInterval = 0

    private var timer: Timer?
    private var autoDismissTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        Defaults.publisher(.reminderIntervalMinutes)
            .sink { [weak self] _ in
                self?.recalculateNextTrigger(fromNow: true)
            }
            .store(in: &cancellables)

        Defaults.publisher(.reminderEnabled)
            .sink { [weak self] change in
                Task { @MainActor in
                    if change.newValue {
                        self?.start()
                    } else {
                        self?.stop()
                    }
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        guard Defaults[.reminderEnabled] else { return }

        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
        }

        if nextTrigger == nil {
            recalculateNextTrigger(fromNow: true)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        cancelAutoDismiss()
        withAnimation(.smooth) {
            showReminder = false
        }
        countdown = 0
        nextTrigger = nil
    }

    func snooze() {
        cancelAutoDismiss()
        withAnimation(.smooth) {
            showReminder = false
        }
        recalculateNextTrigger(fromNow: true)
    }

    func dismiss() {
        cancelAutoDismiss()
        withAnimation(.smooth) {
            showReminder = false
        }
    }

    private func tick() {
        guard Defaults[.reminderEnabled] else {
            stop()
            return
        }

        let now = Date()

        if showReminder {
            if let next = nextTrigger {
                let remaining = max(0, next.timeIntervalSince(now))
                countdown = remaining
            } else {
                countdown = 0
            }
            return
        }

        guard let triggerDate = nextTrigger else {
            recalculateNextTrigger(fromNow: true)
            return
        }

        if now >= triggerDate, isWithinSchedule(now) {
            showReminderNow()
        } else if now > triggerDate {
            recalculateNextTrigger(fromNow: false)
        } else {
            countdown = max(0, triggerDate.timeIntervalSince(now))
        }
    }

    private func showReminderNow() {
        withAnimation(.smooth) {
            showReminder = true
        }

        let intervalSeconds = max(60, TimeInterval(Defaults[.reminderIntervalMinutes] * 60))
        countdown = intervalSeconds
        nextTrigger = Date().addingTimeInterval(intervalSeconds)

        cancelAutoDismiss()
        let dismissAfter = Defaults[.reminderDismissSeconds]
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(dismissAfter))
            await MainActor.run {
                withAnimation(.smooth) {
                    self?.showReminder = false
                }
            }
        }
    }

    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }

    private func recalculateNextTrigger(fromNow: Bool) {
        let now = Date()
        let baseDate = fromNow ? now : (nextTrigger ?? now)
        let intervalSeconds = max(60, TimeInterval(Defaults[.reminderIntervalMinutes] * 60))

        var candidate = baseDate.addingTimeInterval(intervalSeconds)
        var attempts = 0

        while !isWithinSchedule(candidate) && attempts < 7 * 24 {
            candidate = candidate.addingTimeInterval(intervalSeconds)
            attempts += 1
        }

        nextTrigger = candidate
        countdown = max(0, candidate.timeIntervalSince(now))
    }

    private func isWithinSchedule(_ date: Date) -> Bool {
        let schedule = Defaults[.reminderSchedule]
        if schedule.entries.isEmpty {
            return true
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        for entry in schedule.entries where entry.weekday == weekday {
            let startTotal = entry.startHour * 60 + entry.startMinute
            let endTotal = entry.endHour * 60 + entry.endMinute
            let currentTotal = hour * 60 + minute

            if startTotal <= currentTotal && currentTotal <= endTotal {
                return true
            }
        }

        return false
    }
}

