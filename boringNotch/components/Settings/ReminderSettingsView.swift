//
//  ReminderSettingsView.swift
//  boringNotch
//
//  Created by Warren Lu on 08/03/2026.
//

import Defaults
import SwiftUI

struct ReminderSettingsView: View {
    @Default(.reminderEnabled) private var enabled
    @Default(.reminderIntervalMinutes) private var intervalMinutes
    @Default(.reminderSchedule) private var schedule
    @Default(.reminderDismissSeconds) private var dismissSeconds
    @Default(.reminderPersonName) var reminderPersonName


    private let availableIntervals: [Int] = [1, 10, 15, 20, 30, 60]

    // Sanitised binding: snaps any invalid stored value to the nearest valid interval
    private var sanitisedIntervalBinding: Binding<Int> {
        Binding(
            get: {
                availableIntervals.contains(intervalMinutes)
                    ? intervalMinutes
                    : (availableIntervals.min(by: { abs($0 - intervalMinutes) < abs($1 - intervalMinutes) }) ?? 60)
            },
            set: { newValue in
                intervalMinutes = newValue
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Water reminders", isOn: $enabled)

                Picker("Interval", selection: sanitisedIntervalBinding) {
                    ForEach(availableIntervals, id: \.self) { value in
                        Text("\(value) minutes").tag(value)
                    }
                }
                .disabled(!enabled)

                Stepper(value: Binding(
                    get: { dismissSeconds },
                    set: { dismissSeconds = max(3.0, min(10.0, $0)) }
                ), in: 3...10, step: 1) {
                    HStack {
                        Text("Dismiss after")
                        Spacer()
                        Text("\(Int(dismissSeconds)) seconds")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!enabled)
                LabeledContent {
                    TextField("", text: $reminderPersonName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                } label: {
                    Text("Name (optional)")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

            } header: {
                Text("General")
            }

            Section {
                WeekdayScheduleGrid(schedule: $schedule)
            } header: {
                Text("Schedule")
            } footer: {
                Text("Reminders only appear during the selected days and time ranges, using your system timezone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Reminders")
        // Sanitise on appear: if stored value is invalid, reset to closest valid interval
        .onAppear {
            if !availableIntervals.contains(intervalMinutes) {
                intervalMinutes = availableIntervals.min(by: { abs($0 - intervalMinutes) < abs($1 - intervalMinutes) }) ?? 60
            }
        }
    }
}


private struct WeekdayScheduleGrid: View {
    @Binding var schedule: ReminderSchedule

    private var calendar: Calendar { .current }

    private var weekdays: [Int] {
        Array(1...7)
    }

    private func label(for weekday: Int) -> String {
        calendar.weekdaySymbols[weekday - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(weekdays, id: \.self) { weekday in
                HStack {
                    Text(label(for: weekday))
                        .frame(width: 80, alignment: .leading)

                    let binding = Binding<ReminderScheduleEntry?>(
                        get: {
                            schedule.entries.first(where: { $0.weekday == weekday })
                        },
                        set: { newValue in
                            if let existingIndex = schedule.entries.firstIndex(where: { $0.weekday == weekday }) {
                                if let newValue {
                                    schedule.entries[existingIndex] = newValue
                                } else {
                                    schedule.entries.remove(at: existingIndex)
                                }
                            } else if let newValue {
                                schedule.entries.append(newValue)
                            }
                        }
                    )

                    DayScheduleRow(weekday: weekday, entry: binding)
                }
            }
        }
    }
}

private struct DayScheduleRow: View {
    let weekday: Int
    @Binding var entry: ReminderScheduleEntry?

    private func hourMinuteBinding(
        for keyPathHour: WritableKeyPath<ReminderScheduleEntry, Int>,
        _ keyPathMinute: WritableKeyPath<ReminderScheduleEntry, Int>,
        defaultHour: Int
    ) -> Binding<Date> {
        Binding<Date>(
            get: {
                let base = entry ?? ReminderScheduleEntry(
                    weekday: weekday,
                    startHour: defaultHour,
                    startMinute: 0,
                    endHour: defaultHour + 8,
                    endMinute: 0
                )
                var components = DateComponents()
                components.hour = base[keyPath: keyPathHour]
                components.minute = base[keyPath: keyPathMinute]
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                var current = entry ?? ReminderScheduleEntry(
                    weekday: weekday,
                    startHour: defaultHour,
                    startMinute: 0,
                    endHour: defaultHour + 8,
                    endMinute: 0
                )
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                current[keyPath: keyPathHour] = comps.hour ?? current[keyPath: keyPathHour]
                current[keyPath: keyPathMinute] = comps.minute ?? current[keyPath: keyPathMinute]
                entry = current
            }
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { entry != nil },
                set: { isOn in
                    if isOn {
                        if entry == nil {
                            entry = ReminderScheduleEntry(
                                weekday: weekday,
                                startHour: 10,
                                startMinute: 0,
                                endHour: 18,
                                endMinute: 0
                            )
                        }
                    } else {
                        entry = nil
                    }
                }
            ))
            .labelsHidden()
            .frame(width: 24)

            if entry != nil {
                DatePicker(
                    "",
                    selection: hourMinuteBinding(
                        for: \.startHour,
                        \.startMinute,
                        defaultHour: 10
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(width: 90)

                Text("–")

                DatePicker(
                    "",
                    selection: hourMinuteBinding(
                        for: \.endHour,
                        \.endMinute,
                        defaultHour: 18
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(width: 90)
            } else {
                Text("Off")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

