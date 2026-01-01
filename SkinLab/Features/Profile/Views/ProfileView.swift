import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showEditProfile = false
    @State private var showPrivacyCenter = false
    @State private var privacyInitialAction: PrivacyCenterInitialAction?
    @State private var showNotificationSettings = false

    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 渐变背景
                Color.skinLabBackground.ignoresSafeArea()
                
                Circle()
                    .fill(LinearGradient.skinLabLavenderGradient)
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 100, y: -250)
                    .opacity(0.4)
                
                Circle()
                    .fill(LinearGradient.skinLabRoseGradient)
                    .frame(width: 200, height: 200)
                    .blur(radius: 80)
                    .offset(x: -120, y: 300)
                    .opacity(0.3)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        profileHeader
                        
                        if let profile = profile {
                            skinProfileCard(profile)
                        } else {
                            createProfilePrompt
                        }
                        
                        statsSection
                        settingsSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("我的")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showPrivacyCenter) {
                PrivacyCenterView(initialAction: privacyInitialAction)
                    .onDisappear {
                        privacyInitialAction = nil
                    }
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // 外层渐变环
                Circle()
                    .stroke(LinearGradient.skinLabRoseGradient, lineWidth: 3)
                    .frame(width: 110, height: 110)
                
                // 内层渐变填充
                Circle()
                    .fill(LinearGradient.skinLabRoseGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: .skinLabPrimary.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                // 闪光装饰
                SparkleView(size: 14)
                    .offset(x: 50, y: -40)
                
                SparkleView(size: 10)
                    .offset(x: -45, y: 35)
            }
            
            VStack(spacing: 6) {
                if let profile = profile, let skinType = profile.skinType {
                    Text("\(skinType.displayName)肤质")
                        .font(.skinLabTitle3)
                        .foregroundColor(.skinLabText)
                    
                    Text("护肤达人")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.skinLabPrimary.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    Text("尚未设置皮肤档案")
                        .font(.skinLabTitle3)
                        .foregroundColor(.skinLabSubtext)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Create Profile Prompt
    private var createProfilePrompt: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient.skinLabLavenderGradient.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }
            
            VStack(spacing: 8) {
                Text("创建皮肤档案")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
                
                Text("记录你的肤质、问题和目标\n获得更精准的个性化推荐")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showEditProfile = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("开始设置")
                }
            }
            .buttonStyle(SkinLabPrimaryButtonStyle())
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(Color.skinLabCardBackground)
        .cornerRadius(24)
        .skinLabSoftShadow(radius: 15, y: 8)
    }
    
    // MARK: - Skin Profile Card
    private func skinProfileCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                    Text("皮肤档案")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }
                
                Spacer()
                
                Button {
                    showEditProfile = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("编辑")
                    }
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.skinLabPrimary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Divider()
            
            // Age Range
            ProfileRow(label: "年龄", value: profile.ageRange.displayName, icon: "calendar")
            
            // Skin Type
            if let skinType = profile.skinType {
                ProfileRow(label: "肤质", value: skinType.displayName, icon: skinType.icon)
            }
            
            // Concerns
            if !profile.concerns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabSubtext)
                        Text("主要问题")
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    FlowLayout(spacing: 8) {
                        ForEach(profile.concerns, id: \.self) { concern in
                            ConcernTag(concern: concern)
                        }
                    }
                }
            }
            
            // Allergies
            if !profile.allergies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "allergens")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabSubtext)
                        Text("已知过敏")
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    Text(profile.allergies.joined(separator: "、"))
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("我的数据")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            
            HStack(spacing: 12) {
                StatCard(value: "12", label: "分析次数", icon: "camera.fill", gradient: .skinLabPrimaryGradient)
                StatCard(value: "1", label: "追踪周期", icon: "chart.line.uptrend.xyaxis", gradient: .skinLabLavenderGradient)
                StatCard(value: "8", label: "收藏产品", icon: "heart.fill", gradient: .skinLabGoldGradient)
            }
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("设置")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            
            VStack(spacing: 0) {
                Button {
                    showNotificationSettings = true
                } label: {
                    SettingsRow(icon: "bell.fill", title: "通知设置", iconColor: .skinLabPrimary)
                }

                Divider().padding(.leading, 52)

                Button {
                    showPrivacyCenter = true
                    privacyInitialAction = nil
                } label: {
                    SettingsRow(icon: "lock.shield.fill", title: "隐私设置", iconColor: .skinLabSecondary)
                }

                Divider().padding(.leading, 52)

                Button {
                    privacyInitialAction = .exportData
                    showPrivacyCenter = true
                } label: {
                    SettingsRow(icon: "square.and.arrow.up.fill", title: "导出数据", iconColor: .skinLabAccent)
                }

                Divider().padding(.leading, 52)

                Button {
                    privacyInitialAction = .deleteAllData
                    showPrivacyCenter = true
                } label: {
                    SettingsRow(icon: "trash.fill", title: "删除所有数据", iconColor: .skinLabError, isDestructive: true)
                }
            }
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
            .skinLabSoftShadow()
        }
    }
}

// MARK: - Profile Row
struct ProfileRow: View {
    let label: String
    let value: String
    var icon: String = ""
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.skinLabSubtext)
                }
                Text(label)
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
            }
            Spacer()
            Text(value)
                .font(.skinLabBody)
                .foregroundColor(.skinLabText)
        }
    }
}

// MARK: - Concern Tag
struct ConcernTag: View {
    let concern: SkinConcern
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: concern.icon)
                .font(.system(size: 11))
            Text(concern.displayName)
                .font(.skinLabCaption)
        }
        .foregroundColor(.skinLabPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            LinearGradient.skinLabPrimaryGradient.opacity(0.12)
        )
        .cornerRadius(14)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var gradient: LinearGradient = .skinLabPrimaryGradient
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(gradient)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.skinLabText)
            
            Text(label)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    var iconColor: Color = .skinLabPrimary
    var isDestructive: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.skinLabBody)
                .foregroundColor(isDestructive ? .skinLabError : .skinLabText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.skinLabSubtext.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var skinType: SkinType?
    @State private var ageRange: AgeRange = .age25to30
    @State private var selectedConcerns: Set<SkinConcern> = []
    @State private var allergiesText: String = ""
    @State private var gender: Gender?
    
    private var existingProfile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            Form {
                // Skin Type
                Section("肤质类型") {
                    ForEach(SkinType.allCases, id: \.self) { type in
                        Button {
                            skinType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(.skinLabPrimary)
                                    .frame(width: 24)
                                
                                Text(type.displayName)
                                    .foregroundColor(.skinLabText)
                                
                                Spacer()
                                
                                if skinType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.skinLabPrimary)
                                }
                            }
                        }
                    }
                }
                
                // Age Range
                Section("年龄段") {
                    Picker("年龄段", selection: $ageRange) {
                        ForEach(AgeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Concerns
                Section("主要皮肤问题（可多选）") {
                    ForEach(SkinConcern.allCases, id: \.self) { concern in
                        Button {
                            if selectedConcerns.contains(concern) {
                                selectedConcerns.remove(concern)
                            } else {
                                selectedConcerns.insert(concern)
                            }
                        } label: {
                            HStack {
                                Image(systemName: concern.icon)
                                    .foregroundColor(.skinLabPrimary)
                                    .frame(width: 24)
                                
                                Text(concern.displayName)
                                    .foregroundColor(.skinLabText)
                                
                                Spacer()
                                
                                if selectedConcerns.contains(concern) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.skinLabPrimary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                // Allergies
                Section("已知过敏成分") {
                    TextField("例如：酒精、香精（逗号分隔）", text: $allergiesText)
                }
                
                // Gender (Optional)
                Section("性别（可选）") {
                    Picker("性别", selection: $gender) {
                        Text("不选择").tag(nil as Gender?)
                        ForEach([Gender.female, .male, .other], id: \.self) { g in
                            Text(g.displayName).tag(g as Gender?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("皮肤档案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingProfile()
            }
        }
    }
    
    private func loadExistingProfile() {
        guard let profile = existingProfile else { return }
        skinType = profile.skinType
        ageRange = profile.ageRange
        selectedConcerns = Set(profile.concerns)
        allergiesText = profile.allergies.joined(separator: ", ")
        gender = profile.gender.flatMap { Gender(rawValue: $0) }
    }
    
    private func saveProfile() {
        let allergies = allergiesText
            .components(separatedBy: CharacterSet(charactersIn: ",，、"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if let existing = existingProfile {
            // Update existing
            existing.skinType = skinType
            existing.ageRange = ageRange
            existing.concerns = Array(selectedConcerns)
            existing.allergies = allergies
            existing.gender = gender?.rawValue
            existing.updatedAt = Date()
        } else {
            // Create new
            let profile = UserProfile(
                skinType: skinType,
                ageRange: ageRange,
                concerns: Array(selectedConcerns),
                allergies: allergies,
                gender: gender?.rawValue
            )
            modelContext.insert(profile)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    struct CacheData {
        var size: CGSize = .zero
        var frames: [CGRect] = []
    }

    func makeCache(subviews: Subviews) -> CacheData {
        CacheData()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        cache.size = result.size
        cache.frames = result.frames
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        // Use cached frames if available, otherwise recalculate
        let frames = cache.frames.isEmpty ? layout(proposal: proposal, subviews: subviews).frames : cache.frames
        for (index, frame) in frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + maxHeight), frames)
    }
}

#Preview {
    ProfileView()
}
