import SwiftUI

struct CommunityView: View {
    @State private var showSkinTwinMatch = false

    var body: some View {
        ZStack {
            Color.skinLabBackground.ignoresSafeArea()

            Circle()
                .fill(LinearGradient.skinLabLavenderGradient)
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -120, y: -220)
                .opacity(0.3)

            Circle()
                .fill(LinearGradient.skinLabRoseGradient)
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: 140, y: 180)
                .opacity(0.25)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("SkinLab 社群")
                            .font(.skinLabTitle2)
                            .foregroundColor(.skinLabText)
                        Text("分享真实效果，找到相似皮肤的人")
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabSubtext)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    communityCard(
                        title: "今日话题", subtitle: "你最近改变了哪一步护肤？",
                        icon: "bubble.left.and.bubble.right.fill", gradient: .skinLabPrimaryGradient
                    )

                    // 肌肤双胞胎卡片 - 添加导航
                    NavigationLink(destination: SkinTwinMatchView()) {
                        communityCardContent(
                            title: "肌肤双胞胎", subtitle: "匹配相似肤质的有效产品", icon: "person.2.fill",
                            gradient: .skinLabLavenderGradient)
                    }
                    .buttonStyle(.plain)

                    Button {
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                            Text("发布分享")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.skinLabPrimaryGradient)
                        .cornerRadius(26)
                        .shadow(color: .skinLabPrimary.opacity(0.3), radius: 10, y: 6)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationTitle("社群")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func communityCardContent(
        title: String, subtitle: String, icon: String, gradient: LinearGradient
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(gradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
                Text(subtitle)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.skinLabPrimary.opacity(0.6))
        }
        .padding(16)
        .background(Color.skinLabCardBackground)
        .cornerRadius(18)
        .skinLabSoftShadow()
    }

    private func communityCard(
        title: String, subtitle: String, icon: String, gradient: LinearGradient
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(gradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
                Text(subtitle)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.skinLabPrimary.opacity(0.6))
        }
        .padding(16)
        .background(Color.skinLabCardBackground)
        .cornerRadius(18)
        .skinLabSoftShadow()
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
