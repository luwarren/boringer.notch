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
    @Default(.reminderDismissSeconds) private var dismissSeconds
    @Default(.reminderPersonName) var reminderPersonName
    @Default(.reminderScheduleEnabled) private var scheduleEnabled
    @Default(.reminderScheduleStartHour) private var scheduleStartHour
    @Default(.reminderScheduleStartMinute) private var scheduleStartMinute
    @Default(.reminderScheduleEndHour) private var scheduleEndHour
    @Default(.reminderScheduleEndMinute) private var scheduleEndMinute

    private let availableIntervals: [Int] = [1, 10, 15, 20, 30, 60]

    private var sanitisedIntervalBinding: Binding<Int> {
        Binding(
            get: {
                availableIntervals.contains(intervalMinutes)
                    ? intervalMinutes
                    : (availableIntervals.min(by: { abs($0 - intervalMinutes) < abs($1 - intervalMinutes) }) ?? 60)
            },
            set: { intervalMinutes = $0 }
        )
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = scheduleStartHour
                comps.minute = scheduleStartMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                scheduleStartHour = comps.hour ?? scheduleStartHour
                scheduleStartMinute = comps.minute ?? scheduleStartMinute
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = scheduleEndHour
                comps.minute = scheduleEndMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                scheduleEndHour = comps.hour ?? scheduleEndHour
                scheduleEndMinute = comps.minute ?? scheduleEndMinute
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
                Toggle("Scheduled times", isOn: $scheduleEnabled)
                    .disabled(!enabled)

                if scheduleEnabled {
                    DatePicker("Start", selection: startBinding, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: endBinding, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Schedule")
            } footer: {
                Text(scheduleEnabled
                    ? "Reminders only appear between the set times, every day."
                    : "Reminders will occur at all times.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Reminders")
        .onAppear {
            if !availableIntervals.contains(intervalMinutes) {
                intervalMinutes = availableIntervals.min(by: { abs($0 - intervalMinutes) < abs($1 - intervalMinutes) }) ?? 60
            }
        }
    }
}
