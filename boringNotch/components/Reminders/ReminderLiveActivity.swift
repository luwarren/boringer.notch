//
//  ReminderLiveActivity.swift
//  boringNotch
//
//  Created by Warren Lu on 08/03/2026.
//

import Defaults
import SwiftUI

struct ReminderLiveActivity: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var manager = ReminderManager.shared
    @Default(.reminderPersonName) var reminderPersonName

    private var reminderText: String {
        if reminderPersonName.isEmpty {
            return "Drink water!"
        } else {
            return "Drink water, \(reminderPersonName)!"
        }
    }

    var body: some View {
        if Defaults[.sneakPeekStyles] == .inline {
            inlineLayout
        } else {
            defaultLayout
        }
    }
    
    @ViewBuilder
    private var inlineLayout: some View {
        HStack(spacing: 0) {
            Text(reminderText)
                .lineLimit(1)
                .hidden()
                .overlay(
                    Text("💧")
                        .font(.title2)
                        .padding(.trailing, 10), // Optional: small visual breathing room
                    alignment: .leading
                )

            // Notch gap — stays perfectly aligned with the hardware notch
            Rectangle()
                .fill(.black)
                .frame(width: vm.closedNotchSize.width)

            // Right side — actual text dynamically dictating the width of BOTH sides
            Text(reminderText)
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.leading, 10) // Optional: small visual breathing room
        }
        .frame(height: vm.effectiveClosedNotchHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.snooze()
        }
    }
    
    @ViewBuilder
    private var defaultLayout: some View {
        HStack(spacing: 6) {
            Text("💧")
            Text(reminderText)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.8))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            manager.snooze()
        }
    }
}
