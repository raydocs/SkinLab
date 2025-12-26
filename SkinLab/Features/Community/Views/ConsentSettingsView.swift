// SkinLab/Features/Community/Views/ConsentSettingsView.swift
import SwiftUI

/// 隐私同意设置视图
struct ConsentSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedLevel: ConsentLevel
    var onSave: ((ConsentLevel) -> Void)?

    @State private var tempSelection: ConsentLevel

    init(selectedLevel: Binding<ConsentLevel>, onSave: ((ConsentLevel) -> Void)? = nil) {
        self._selectedLevel = selectedLevel
        self.onSave = onSave
        self._tempSelection = State(initialValue: selectedLevel.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.skinLabBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 头部说明
                        headerSection

                        // 隐私保护说明
                        privacyGuaranteeCard

                        // 选项列表
                        optionsSection

                        // 保存按钮
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("隐私设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.skinLabSubtext)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.skinLabLavenderGradient.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(LinearGradient.skinLabLavenderGradient)
            }

            Text("选择您的数据分享等级")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            Text("控制您希望与社区分享的数据范围")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Privacy Guarantee Card

    private var privacyGuaranteeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 16))
                    .foregroundColor(.skinLabSuccess)

                Text("隐私保护承诺")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            VStack(alignment: .leading, spacing: 8) {
                guaranteeItem("您的照片永远不会被分享")
                guaranteeItem("您的真实姓名永远不会被分享")
                guaranteeItem("您的精确位置永远不会被分享")
                guaranteeItem("您可以随时更改或撤销同意")
            }
        }
        .padding(16)
        .background(Color.skinLabSuccess.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.skinLabSuccess.opacity(0.2), lineWidth: 1)
        )
    }

    private func guaranteeItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.skinLabSuccess)

            Text(text)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabText)
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 12) {
            ForEach(ConsentLevel.allCases, id: \.self) { level in
                ConsentOptionCard(
                    level: level,
                    isSelected: tempSelection == level,
                    onSelect: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            tempSelection = level
                        }
                    }
                )
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            selectedLevel = tempSelection
            onSave?(tempSelection)
            dismiss()
        } label: {
            Text("保存设置")
        }
        .buttonStyle(SkinLabPrimaryButtonStyle())
        .padding(.top, 8)
    }
}

// MARK: - Consent Option Card

struct ConsentOptionCard: View {
    let level: ConsentLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 选中指示器
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.skinLabPrimary : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(LinearGradient.skinLabPrimaryGradient)
                            .frame(width: 14, height: 14)
                    }
                }

                // 等级信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(level.rawValue)
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)

                        if level == .none {
                            levelBadge("私密", color: .gray)
                        } else if level == .pseudonymous {
                            levelBadge("推荐", color: .skinLabPrimary)
                        }
                    }

                    Text(level.description)
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                        .fixedSize(horizontal: false, vertical: true)

                    // 数据说明
                    if level != .none {
                        dataShareInfo(for: level)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                isSelected
                    ? Color.skinLabPrimary.opacity(0.08)
                    : Color.skinLabCardBackground
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Color.skinLabPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
            .skinLabSoftShadow(radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
        }
        .buttonStyle(.plain)
    }

    private func levelBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    @ViewBuilder
    private func dataShareInfo(for level: ConsentLevel) -> some View {
        HStack(spacing: 12) {
            switch level {
            case .anonymous:
                dataItem(icon: "chart.bar", text: "仅算法使用")
            case .pseudonymous:
                dataItem(icon: "person.crop.circle", text: "匿名资料")
                dataItem(icon: "sparkles", text: "有效产品")
            case .public:
                dataItem(icon: "person.crop.circle", text: "扩展资料")
                dataItem(icon: "text.bubble", text: "护肤经验")
            default:
                EmptyView()
            }
        }
        .padding(.top, 4)
    }

    private func dataItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11))
        }
        .foregroundColor(.skinLabSecondary)
    }
}

// MARK: - Preview

#Preview {
    ConsentSettingsView(
        selectedLevel: .constant(.none)
    )
}
