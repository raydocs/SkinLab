import SwiftUI
import SwiftData

struct TrackingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: TrackingSession

    var body: some View {
        TrackingDetailViewContent(session: session, modelContext: modelContext)
    }
}

private struct TrackingDetailViewContent: View {
    @Bindable var session: TrackingSession
    @StateObject private var viewModel: TrackingDetailViewModel

    @State private var showCamera = false
    @State private var showCheckIn = false
    @State private var capturedImage: UIImage?
    @State private var capturedStandardization: PhotoStandardizationMetadata?
    @State private var showProductPicker = false

    init(session: TrackingSession, modelContext: ModelContext) {
        self.session = session
        _viewModel = StateObject(wrappedValue: TrackingDetailViewModel(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Header
                progressHeader

                // Timeline
                timelineSection

                // Products Used
                productsSection

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color.skinLabBackground)
        .navigationTitle("追踪详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCheckIn) {
            CheckInView(
                session: session,
                image: capturedImage,
                standardization: capturedStandardization
            )
        }
        .sheet(isPresented: $viewModel.showReport) {
            if let report = viewModel.generatedReport {
                NavigationStack {
                    TrackingReportView(report: report)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    viewModel.showReport = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showProductPicker) {
            ProductPickerView(
                selectedProducts: Binding(
                    get: { session.targetProducts },
                    set: { session.targetProducts = $0 }
                )
            )
        }
        .alert("报告生成失败", isPresented: Binding(
            get: { viewModel.reportError != nil },
            set: { if !$0 { viewModel.reportError = nil } }
        )) {
            Button("确定") {
                viewModel.reportError = nil
            }
        } message: {
            Text(viewModel.reportError ?? "")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPreviewView(
                capturedImage: $capturedImage,
                capturedStandardization: $capturedStandardization
            )
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                showCheckIn = true
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .trim(from: 0, to: session.progress)
                    .stroke(Color.freshPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .background(
                        Circle()
                            .stroke(Color.freshPrimary.opacity(0.1), lineWidth: 8)
                    )

                VStack(spacing: 4) {
                    Text("\(session.duration)")
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .foregroundColor(.freshPrimary)
                    Text("/ 28天")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }

            // Stats Row
            HStack(spacing: 32) {
                VStack {
                    Text("\(session.checkIns.count)")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("已打卡")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                VStack {
                    Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("开始日期")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                VStack {
                    Text("\(28 - session.duration)")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("剩余天数")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
        }
        .freshGlassCard()
    }

    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("追踪时间线")
                .font(.skinLabHeadline)

            // Check-in nodes
            HStack(spacing: 0) {
                ForEach(TrackingConstants.checkInDays, id: \.self) { day in
                    VStack(spacing: 8) {
                        timelineNode(for: day)
                        Text("Day \(day)")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    if day < 28 {
                        Rectangle()
                            .fill(isCompleted(day: day) ? Color.freshPrimary : Color.gray.opacity(0.2))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Check-in list
            ForEach(session.checkIns.sorted(by: { $0.day < $1.day })) { checkIn in
                CheckInRow(checkIn: checkIn)
            }
        }
        .freshGlassCard()
    }

    private func timelineNode(for day: Int) -> some View {
        let completed = isCompleted(day: day)
        let current = session.duration == day

        if completed {
            return AnyView(
                Circle()
                    .fill(Color.freshPrimary)
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "checkmark").font(.caption2).foregroundColor(.white))
            )
        } else if current {
            return AnyView(
                Circle()
                    .stroke(Color.freshPrimary, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().fill(Color.freshPrimary).frame(width: 12, height: 12))
            )
        } else {
            return AnyView(
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 20, height: 20)
            )
        }
    }

    private func isCompleted(day: Int) -> Bool {
        session.checkIns.contains { $0.day == day }
    }

    // MARK: - Products Section
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("使用的产品")
                    .font(.skinLabHeadline)

                Spacer()

                Button("添加") {
                    showProductPicker = true
                }
                .font(.skinLabSubheadline)
                .foregroundColor(.freshPrimary)
            }

            if session.targetProducts.isEmpty {
                Text("尚未添加产品")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(session.targetProducts, id: \.self) { productId in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Text(productId)
                            .font(.skinLabBody)

                        Spacer()
                    }
                }
            }
        }
        .freshGlassCard()
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Due checkpoint: actionable
            if let dueDay = session.nextCheckInDay {
                Button {
                    showCamera = true
                } label: {
                    Text("记录第 \(dueDay) 天")
                }
                .buttonStyle(FreshGlassButton(color: .freshPrimary))
            }
            // No due checkpoint but next planned exists: show non-actionable
            else if let nextPlanned = session.nextPlannedCheckInDay {
                Text("下次打卡 Day \(nextPlanned)")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            }

            if session.duration >= 28 && session.status == .active {
                Button {
                    viewModel.completeSession(session)
                } label: {
                    Text("完成追踪")
                }
                .buttonStyle(FreshGlassButton(color: .freshPrimary))
            }

            Button {
                Task {
                    await viewModel.generateReport(for: session)
                }
            } label: {
                Text(viewModel.isGeneratingReport ? "生成中..." : "生成报告")
            }
            .buttonStyle(FreshSecondaryButton())
            .disabled(viewModel.isGeneratingReport || session.checkIns.count < 2)
        }
    }
}

#Preview {
    NavigationStack {
        TrackingDetailView(session: TrackingSession())
    }
}
