import Defaults
import SwiftUI

struct ReminderLiveActivity: View {
    @ObservedObject var manager = ReminderManager.shared

    private var intervalSeconds: TimeInterval {
        max(60, TimeInterval(Defaults[.reminderIntervalMinutes] * 60))
    }

    private var progress: Double {
        guard intervalSeconds > 0 else { return 0 }
        return 1.0 - min(1.0, max(0.0, manager.countdown / intervalSeconds))
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("⏰ Drink water!")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 80)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .scaleEffect(manager.showReminder ? 1.05 : 1.0, anchor: .center)
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: manager.showReminder)
        .onTapGesture {
            manager.snooze()
        }
    }
}

