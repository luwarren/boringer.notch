import Defaults
import SwiftUI

struct ReminderLiveActivity: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var manager = ReminderManager.shared

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Text("Drink water!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }

            Rectangle()
                .fill(.black)
                .frame(width: vm.closedNotchSize.width + 10)

            HStack {
                Text("💧")
                    .font(.title2)
            }
            .frame(width: 76, alignment: .trailing)
        }
        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.snooze()
        }
    }
}
