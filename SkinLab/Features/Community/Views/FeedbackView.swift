// SkinLab/Features/Community/Views/FeedbackView.swift
import SwiftUI

/// 匹配反馈视图
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    let matchId: UUID
    var onSubmit: ((Int, Bool, String?) -> Void)?

    @State private var accuracyScore: Int = 3
    @State private var isHelpful: Bool = true
    @State private var feedbackText: String = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.skinLabBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // 头部
                        headerSection

                        // 准确度评分
                        accuracySection

                        // 是否有帮助
                        helpfulSection

                        // 文字反馈 (可选)
                        textFeedbackSection

                        // 提交按钮
                        submitButton
                    }
                    .padding()
                }
            }
            .navigationTitle("提供反馈")
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
                    .fill(LinearGradient.skinLabRoseGradient.opacity(0.2))
                    .frame(width: 70, height: 70)

                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient.skinLabRoseGradient)
            }

            Text("您的反馈很重要")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            Text("帮助我们优化匹配算法")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Accuracy Section

    private var accuracySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("匹配准确度如何？")
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)

            HStack(spacing: 8) {
                ForEach(1 ... 5, id: \.self) { score in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            accuracyScore = score
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        score <= accuracyScore
                                            ? LinearGradient.skinLabPrimaryGradient
                                            : LinearGradient(
                                                colors: [Color.gray.opacity(0.15)],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                    )
                                    .frame(width: 50, height: 50)

                                Text("\(score)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(score <= accuracyScore ? .white : .gray)
                            }
                            .scaleEffect(score == accuracyScore ? 1.1 : 1.0)

                            Text(scoreLabel(for: score))
                                .font(.system(size: 10))
                                .foregroundColor(
                                    score == accuracyScore ? .skinLabPrimary : .skinLabSubtext
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.skinLabCardBackground)
        .cornerRadius(18)
        .skinLabSoftShadow(radius: 8, y: 4)
    }

    private func scoreLabel(for score: Int) -> String {
        switch score {
        case 1: "很差"
        case 2: "较差"
        case 3: "一般"
        case 4: "较好"
        case 5: "很准"
        default: ""
        }
    }

    // MARK: - Helpful Section

    private var helpfulSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("产品推荐有帮助吗？")
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)

            HStack(spacing: 16) {
                helpfulButton(
                    isYes: true,
                    selected: isHelpful,
                    icon: "hand.thumbsup.fill",
                    text: "有帮助"
                )

                helpfulButton(
                    isYes: false,
                    selected: !isHelpful,
                    icon: "hand.thumbsdown.fill",
                    text: "没帮助"
                )
            }
        }
        .padding(20)
        .background(Color.skinLabCardBackground)
        .cornerRadius(18)
        .skinLabSoftShadow(radius: 8, y: 4)
    }

    private func helpfulButton(isYes: Bool, selected: Bool, icon: String, text: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHelpful = isYes
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(text)
                    .font(.skinLabSubheadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                selected
                    ? (isYes
                        ? Color.skinLabSuccess.opacity(0.15) : Color.skinLabError.opacity(0.15))
                    : Color.gray.opacity(0.08)
            )
            .foregroundColor(
                selected
                    ? (isYes ? .skinLabSuccess : .skinLabError)
                    : .skinLabSubtext
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        selected
                            ? (isYes ? Color.skinLabSuccess : Color.skinLabError)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Feedback Section

    private var textFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("补充说明")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Text("(可选)")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            TextEditor(text: $feedbackText)
                .font(.skinLabBody)
                .frame(minHeight: 100)
                .padding(12)
                .background(Color.skinLabCardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.skinLabPrimary.opacity(0.15), lineWidth: 1)
                )

            Text("分享您的使用体验，帮助其他用户")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            submitFeedback()
        } label: {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
            } else {
                Text("提交反馈")
            }
        }
        .buttonStyle(SkinLabPrimaryButtonStyle())
        .disabled(isSubmitting)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func submitFeedback() {
        isSubmitting = true

        let text = feedbackText.isEmpty ? nil : feedbackText
        onSubmit?(accuracyScore, isHelpful, text)

        // 模拟提交延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    FeedbackView(matchId: UUID())
}
