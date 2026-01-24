import SwiftUI
import UIKit
import os.log

/// View displayed when the app encounters a critical initialization error
/// Provides recovery options for the user instead of crashing
struct AppRecoveryView: View {
    let error: Error?
    let onResetData: () -> Void

    @State private var showingResetConfirmation = false
    @State private var isResetting = false

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.skinlab",
        category: "AppRecovery"
    )

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            // Title
            Text("无法启动应用")
                .font(.title)
                .fontWeight(.bold)

            // Description
            Text("SkinLab 遇到了一个问题，无法正常启动。这可能是由于数据损坏导致的。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Error details (collapsible)
            if let error = error {
                DisclosureGroup("技术详情") {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .tint(.secondary)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 16) {
                // Reset data button
                Button {
                    showingResetConfirmation = true
                } label: {
                    HStack {
                        if isResetting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("重置应用数据")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isResetting)
                .padding(.horizontal, 32)

                // Contact support button
                Button {
                    openSupportEmail()
                } label: {
                    HStack {
                        Image(systemName: "envelope")
                        Text("联系支持")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
        .confirmationDialog(
            "确认重置",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("重置所有数据", role: .destructive) {
                performReset()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("这将删除所有应用数据，包括您的皮肤分析记录和设置。此操作无法撤销。")
        }
    }

    private func performReset() {
        isResetting = true
        Self.logger.info("User initiated app data reset from recovery view")

        // Give UI time to update, then call reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            onResetData()
            // Reset the loading state after callback completes
            // (The parent handles showing completion alert)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isResetting = false
            }
        }
    }

    private func openSupportEmail() {
        Self.logger.info("User requested support contact from recovery view")

        let email = "support@skinlab.app"
        let subject = "SkinLab App Crash Report"
        let body = """
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)

        Error: \(error?.localizedDescription ?? "Unknown error")

        Please describe what happened:

        """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    AppRecoveryView(
        error: NSError(
            domain: "com.skinlab",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to initialize ModelContainer"]
        ),
        onResetData: {}
    )
}
