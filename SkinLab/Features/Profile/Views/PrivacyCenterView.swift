// SkinLab/Features/Profile/Views/PrivacyCenterView.swift
import SwiftData
import SwiftUI

/// 隐私控制中心 - P0-2 Privacy Control Center
///
/// 功能:
/// - 分级数据同意控制
/// - 本地优先模式
/// - 数据去向透明化
/// - 照片存储设置
struct PrivacyCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @AppStorage("privacy.consentLevel") private var consentLevel: String = ConsentLevel.anonymous.rawValue
    @AppStorage("privacy.localOnlyMode") private var localOnlyMode: Bool = false
    @AppStorage("privacy.storePhotosLocally") private var storePhotosLocally: Bool = true
    @AppStorage("privacy.autoDeletePhotos") private var autoDeletePhotos: Bool = false

    @State private var showConsentSheet = false
    @State private var showDataExportSheet = false
    @State private var showDeleteAlert = false
    private let initialAction: PrivacyCenterInitialAction?

    private var profile: UserProfile? {
        profiles.first
    }

    private var currentConsent: ConsentLevel {
        ConsentLevel(rawValue: consentLevel) ?? .anonymous
    }

    init(initialAction: PrivacyCenterInitialAction? = nil) {
        self.initialAction = initialAction
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 渐变背景
                Color.skinLabBackground.ignoresSafeArea()

                Circle()
                    .fill(LinearGradient.skinLabLavenderGradient)
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: -100, y: -200)
                    .opacity(0.3)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        consentLevelCard
                        localModeCard
                        photoStorageCard
                        dataTransparencyCard
                        dataManagementCard
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("隐私控制中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.skinLabPrimary)
                }
            }
            .sheet(isPresented: $showConsentSheet) {
                ConsentLevelSheet(selectedLevel: $consentLevel)
            }
            .sheet(isPresented: $showDataExportSheet) {
                DataExportView()
            }
            .alert("删除所有数据", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("此操作将删除所有分析记录、追踪数据和个人资料。此操作不可恢复。")
            }
            .onAppear {
                if let action = initialAction {
                    switch action {
                    case .exportData:
                        showDataExportSheet = true
                    case .deleteAllData:
                        showDeleteAlert = true
                    }
                }
            }
        }
    }

    private func deleteAllData() {
        deleteAll(UserProfile.self)
        deleteAll(SkinAnalysisRecord.self)
        deleteAll(TrackingSession.self)
        deleteAll(ProductRecord.self)
        deleteAll(SkincareRoutineRecord.self)
        deleteAll(IngredientExposureRecord.self)
        deleteAll(UserIngredientPreference.self)
        deleteAll(MatchResultRecord.self)
        deleteAll(UserFeedbackRecord.self)
        do {
            try modelContext.save()
            AppLogger.data(operation: .delete, entity: "All user data", success: true)
        } catch {
            AppLogger.data(operation: .delete, entity: "All user data", success: false, error: error)
        }
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        let descriptor = FetchDescriptor<T>()
        do {
            let items = try modelContext.fetch(descriptor)
            for item in items {
                modelContext.delete(item)
            }
            AppLogger.data(operation: .delete, entity: String(describing: T.self), success: true, count: items.count)
        } catch {
            AppLogger.data(operation: .delete, entity: String(describing: T.self), success: false, error: error)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.skinLabLavenderGradient.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.skinLabLavenderGradient)
            }

            VStack(spacing: 6) {
                Text("您的隐私，您做主")
                    .font(.skinLabTitle2)
                    .foregroundColor(.skinLabText)

                Text("完全透明的数据控制")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Consent Level Card

    private var consentLevelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(LinearGradient.skinLabLavenderGradient)
                Text("数据分享等级")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            Divider()

            Button {
                showConsentSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentConsent.rawValue)
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabText)

                        Text(currentConsent.description)
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.skinLabSubtext)
                }
            }

            // Privacy Badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.skinLabSecondary)

                Text(localOnlyMode ? "本地模式已启用" : "数据加密保护")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.skinLabSecondary.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Local Mode Card

    private var localModeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive.fill")
                    .foregroundStyle(LinearGradient.skinLabAccentGradient)
                Text("本地优先模式")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            Divider()

            Toggle(isOn: $localOnlyMode) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("仅本地存储")
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)

                    Text(localOnlyMode ?
                        "所有数据仅存储在您的设备上，不会上传云端" :
                        "允许云端同步以获得更好的体验")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
            .tint(.skinLabAccent)

            if localOnlyMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.skinLabAccent)

                        Text("本地模式限制")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        FeatureStatus(available: false, text: "无法参与社区匹配")
                        FeatureStatus(available: false, text: "无法查看皮肤双胞胎推荐")
                        FeatureStatus(available: true, text: "可使用AI分析和追踪")
                        FeatureStatus(available: true, text: "数据完全离线")
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Photo Storage Card

    private var photoStorageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("照片存储设置")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            Divider()

            Toggle(isOn: $storePhotosLocally) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("本地存储照片")
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)

                    Text("分析后的照片保存在设备相册，不上传服务器")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
            .tint(.skinLabPrimary)

            Divider()

            Toggle(isOn: $autoDeletePhotos) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("分析后自动删除")
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)

                    Text("AI分析完成后立即删除原始照片")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
            .tint(.skinLabPrimary)
            .disabled(!storePhotosLocally)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Data Transparency Card

    private var dataTransparencyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .foregroundStyle(LinearGradient.skinLabLavenderGradient)
                Text("数据去向透明")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                DataFlowRow(
                    icon: "camera.fill",
                    title: "分析照片",
                    destination: storePhotosLocally ? "仅本地存储" : "本地存储",
                    purpose: "AI皮肤分析",
                    isPrivate: storePhotosLocally
                )

                Divider()

                DataFlowRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "追踪数据",
                    destination: localOnlyMode ? "仅本地设备" : "本地 + 云端备份",
                    purpose: "效果验证与报告",
                    isPrivate: localOnlyMode
                )

                Divider()

                DataFlowRow(
                    icon: "person.fill",
                    title: "个人资料",
                    destination: localOnlyMode || currentConsent == .none ? "仅本地设备" : "匿名化后参与匹配",
                    purpose: "个性化分析",
                    isPrivate: localOnlyMode || currentConsent == .none
                )
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Data Management Card

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "gear.badge.checkmark")
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("数据管理")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            Divider()

            Button {
                showDataExportSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(.skinLabAccent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("导出所有数据")
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabText)

                        Text("下载您的完整数据副本")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.skinLabSubtext)
                }
            }

            Divider()

            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.skinLabError)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("删除所有数据")
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabError)

                        Text("永久删除所有分析和追踪记录")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.skinLabSubtext)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
}

// MARK: - Feature Status Row

struct FeatureStatus: View {
    let available: Bool
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(available ? .green : .orange)

            Text(text)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
    }
}

// MARK: - Data Flow Row

struct DataFlowRow: View {
    let icon: String
    let title: String
    let destination: String
    let purpose: String
    let isPrivate: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.skinLabPrimary.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.skinLabPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.skinLabBody)
                    .foregroundColor(.skinLabText)

                HStack(spacing: 4) {
                    Image(systemName: isPrivate ? "lock.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 10))
                    Text("存储位置: \(destination)")
                        .font(.skinLabCaption)
                }
                .foregroundColor(isPrivate ? .green : .skinLabSubtext)

                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                    Text("用途: \(purpose)")
                        .font(.skinLabCaption)
                }
                .foregroundColor(.skinLabSubtext)
            }

            Spacer()
        }
    }
}

enum PrivacyCenterInitialAction {
    case exportData
    case deleteAllData
}

// MARK: - Consent Level Sheet

struct ConsentLevelSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLevel: String
    @State private var tempSelection: ConsentLevel

    init(selectedLevel: Binding<String>) {
        self._selectedLevel = selectedLevel
        self._tempSelection = State(initialValue: ConsentLevel(rawValue: selectedLevel.wrappedValue) ?? .anonymous)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("选择您希望与SkinLab社区分享的数据等级。您可以随时更改此设置。")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSubtext)
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(ConsentLevel.allCases, id: \.self) { level in
                        Button {
                            tempSelection = level
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(
                                            tempSelection == level ? Color.skinLabPrimary : Color.gray.opacity(0.3),
                                            lineWidth: 2
                                        )
                                        .frame(width: 22, height: 22)

                                    if tempSelection == level {
                                        Circle()
                                            .fill(Color.skinLabPrimary)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(level.rawValue)
                                        .font(.skinLabBody)
                                        .foregroundColor(.skinLabText)

                                    Text(level.detailedDescription)
                                        .font(.skinLabCaption)
                                        .foregroundColor(.skinLabSubtext)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("数据分享等级")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        selectedLevel = tempSelection.rawValue
                        dismiss()
                    }
                    .foregroundColor(.skinLabPrimary)
                }
            }
        }
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var analyses: [SkinAnalysisRecord]
    @Query private var sessions: [TrackingSession]
    @Query private var products: [ProductRecord]

    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient.skinLabAccentGradient.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LinearGradient.skinLabAccentGradient)
                }

                VStack(spacing: 12) {
                    Text("导出所有数据")
                        .font(.skinLabTitle2)
                        .foregroundColor(.skinLabText)

                    Text("将创建包含以下内容的JSON文件:\n• 皮肤分析记录\n• 追踪数据\n• 个人资料\n• 产品收藏")
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabSubtext)
                        .multilineTextAlignment(.center)
                }

                if isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportProgress)
                            .tint(.skinLabAccent)

                        Text("导出中... \(Int(exportProgress * 100))%")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        startExport()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text(isExporting ? "导出中..." : "开始导出")
                        }
                    }
                    .buttonStyle(SkinLabPrimaryButtonStyle())
                    .disabled(isExporting)

                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.skinLabSubtext)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("导出失败", isPresented: .constant(exportError != nil)) {
            Button("确定") { exportError = nil }
        } message: {
            if let exportError {
                Text(exportError)
            }
        }
    }

    private func startExport() {
        guard !isExporting else { return }
        isExporting = true
        exportProgress = 0.1

        Task { @MainActor in
            do {
                let payload = ExportPayload(
                    exportedAt: Date(),
                    profiles: profiles.map(UserProfileExport.init),
                    analyses: analyses.compactMap(SkinAnalysisRecordExport.init),
                    sessions: sessions.map(TrackingSessionExport.init),
                    products: products.map(ProductRecordExport.init)
                )

                exportProgress = 0.6
                let data = try JSONEncoder().encode(payload)
                exportProgress = 0.8

                let fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("SkinLab_Data_Export_\(Int(Date().timeIntervalSince1970)).json")
                try data.write(to: fileURL, options: .atomic)
                exportURL = fileURL
                exportProgress = 1.0
                isExporting = false
                showShareSheet = true
            } catch {
                AppLogger.error("Data export failed", error: error)
                exportError = "导出失败，请稍后重试"
                isExporting = false
                exportProgress = 0.0
            }
        }
    }

    private struct ExportPayload: Codable {
        let exportedAt: Date
        let profiles: [UserProfileExport]
        let analyses: [SkinAnalysisRecordExport]
        let sessions: [TrackingSessionExport]
        let products: [ProductRecordExport]
    }

    private struct UserProfileExport: Codable {
        let id: UUID
        let skinTypeRaw: String?
        let ageRangeRaw: String
        let concernsRaw: [String]
        let allergies: [String]
        let gender: String?
        let region: String?
        let climateRaw: String?
        let uvExposureRaw: String?
        let pregnancyStatusRaw: String
        let activePrescriptions: [String]
        let preferredTextureRaw: String?
        let fragranceToleranceRaw: String
        let budgetLevelRaw: String
        let routinePreferencesData: Data?
        let fingerprintData: Data?
        let fingerprintUpdatedAt: Date?
        let consentLevelRaw: String
        let consentUpdatedAt: Date?
        let consentVersion: String?
        let anonymousProfileData: Data?
        let lastMatchedAt: Date?
        let createdAt: Date
        let updatedAt: Date

        init(from profile: UserProfile) {
            id = profile.id
            skinTypeRaw = profile.skinTypeRaw
            ageRangeRaw = profile.ageRangeRaw
            concernsRaw = profile.concernsRaw
            allergies = profile.allergies
            gender = profile.gender
            region = profile.region
            climateRaw = profile.climateRaw
            uvExposureRaw = profile.uvExposureRaw
            pregnancyStatusRaw = profile.pregnancyStatusRaw
            activePrescriptions = profile.activePrescriptions
            preferredTextureRaw = profile.preferredTextureRaw
            fragranceToleranceRaw = profile.fragranceToleranceRaw
            budgetLevelRaw = profile.budgetLevelRaw
            routinePreferencesData = profile.routinePreferencesData
            fingerprintData = profile.fingerprintData
            fingerprintUpdatedAt = profile.fingerprintUpdatedAt
            consentLevelRaw = profile.consentLevelRaw
            consentUpdatedAt = profile.consentUpdatedAt
            consentVersion = profile.consentVersion
            anonymousProfileData = profile.anonymousProfileData
            lastMatchedAt = profile.lastMatchedAt
            createdAt = profile.createdAt
            updatedAt = profile.updatedAt
        }
    }

    private struct SkinAnalysisRecordExport: Codable {
        let id: UUID
        let skinType: String
        let skinAge: Int
        let overallScore: Int
        let issues: IssueScores?
        let regions: RegionScores?
        let recommendations: [String]
        let analyzedAt: Date
        let photoPath: String?
        let confidenceScore: Int
        let imageQuality: ImageQuality?

        init?(from record: SkinAnalysisRecord) {
            id = record.id
            skinType = record.skinType
            skinAge = record.skinAge
            overallScore = record.overallScore
            issues = Self.decodeOrNil(IssueScores.self, from: record.issuesData, label: "SkinAnalysisRecord.issuesData")
            regions = Self.decodeOrNil(
                RegionScores.self,
                from: record.regionsData,
                label: "SkinAnalysisRecord.regionsData"
            )
            recommendations = record.recommendations
            analyzedAt = record.analyzedAt
            photoPath = record.photoPath
            confidenceScore = record.confidenceScore
            imageQuality = Self.decodeOrNil(
                ImageQuality.self,
                from: record.qualityData,
                label: "SkinAnalysisRecord.qualityData"
            )
        }

        /// Decode with logging on failure, returning nil to avoid interrupting export
        private static func decodeOrNil<T: Decodable>(_ type: T.Type, from data: Data?, label: String) -> T? {
            guard let data else { return nil }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                AppLogger.error("Export decode failed: \(label)", error: error)
                return nil
            }
        }
    }

    private struct TrackingSessionExport: Codable {
        let id: UUID
        let startDate: Date
        let endDate: Date?
        let statusRaw: String
        let targetProducts: [String]
        let checkIns: [CheckIn]
        let notes: String?

        init(from session: TrackingSession) {
            id = session.id
            startDate = session.startDate
            endDate = session.endDate
            statusRaw = session.statusRaw
            targetProducts = session.targetProducts
            checkIns = session.checkIns
            notes = session.notes
        }
    }

    private struct ProductRecordExport: Codable {
        let id: UUID
        let name: String
        let brand: String
        let categoryRaw: String
        let ingredients: [Ingredient]?
        let skinTypesRaw: [String]
        let concernsRaw: [String]
        let priceRangeRaw: String
        let imageUrl: String?
        let effectiveRate: Double?
        let sampleSize: Int?
        let averageRating: Double?
        let updatedAt: Date

        init(from record: ProductRecord) {
            id = record.id
            name = record.name
            brand = record.brand
            categoryRaw = record.categoryRaw
            ingredients = Self.decodeOrNil(
                [Ingredient].self,
                from: record.ingredientsData,
                label: "ProductRecord.ingredientsData"
            )
            skinTypesRaw = record.skinTypesRaw
            concernsRaw = record.concernsRaw
            priceRangeRaw = record.priceRangeRaw
            imageUrl = record.imageUrl
            effectiveRate = record.effectiveRate
            sampleSize = record.sampleSize
            averageRating = record.averageRating
            updatedAt = record.updatedAt
        }

        /// Decode with logging on failure, returning nil to avoid interrupting export
        private static func decodeOrNil<T: Decodable>(_ type: T.Type, from data: Data?, label: String) -> T? {
            guard let data else { return nil }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                AppLogger.error("Export decode failed: \(label)", error: error)
                return nil
            }
        }
    }
}

#Preview {
    PrivacyCenterView()
}
