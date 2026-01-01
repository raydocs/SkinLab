import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("notifications.enabled") private var notificationsEnabled = true
    @AppStorage("notifications.trackingReminders") private var trackingReminders = true
    @AppStorage("notifications.weeklyReport") private var weeklyReport = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.skinLabBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                        Text("通知设置")
                            .font(.skinLabTitle2)
                            .foregroundColor(.skinLabText)
                        Text("用于提醒打卡和查看周报")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    VStack(spacing: 0) {
                        Toggle("启用通知", isOn: $notificationsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .skinLabPrimary))
                            .padding()

                        Divider()

                        Toggle("追踪打卡提醒", isOn: $trackingReminders)
                            .toggleStyle(SwitchToggleStyle(tint: .skinLabPrimary))
                            .padding()
                            .disabled(!notificationsEnabled)

                        Divider()

                        Toggle("每周报告提醒", isOn: $weeklyReport)
                            .toggleStyle(SwitchToggleStyle(tint: .skinLabPrimary))
                            .padding()
                            .disabled(!notificationsEnabled)
                    }
                    .background(Color.skinLabCardBackground)
                    .cornerRadius(16)
                    .skinLabSoftShadow()

                    if !notificationsEnabled {
                        Text("系统通知权限需在系统设置中开启")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("通知设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.skinLabPrimary)
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
