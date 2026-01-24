import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]
        // 浪漫粉色系选中状态
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 1.0, green: 0.68, blue: 0.78, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 1.0, green: 0.68, blue: 0.78, alpha: 1.0), .font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
                .accessibilityLabel("首页")
                .accessibilityHint("查看皮肤状态和护肤建议")

            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: selectedTab == 1 ? "camera.fill" : "camera")
                }
                .tag(1)
                .accessibilityLabel("分析")
                .accessibilityHint("拍照分析皮肤状态")

            TrackingView()
                .tabItem {
                    Label("追踪", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
                .accessibilityLabel("追踪")
                .accessibilityHint("28天效果追踪")

            ProductsView()
                .tabItem {
                    Label("产品", systemImage: "sparkles")
                }
                .tag(3)
                .accessibilityLabel("产品")
                .accessibilityHint("护肤产品推荐和成分扫描")

            CommunityView()
                .tabItem {
                    Label("社区", systemImage: selectedTab == 4 ? "heart.fill" : "heart")
                }
                .tag(4)
                .accessibilityLabel("社区")
                .accessibilityHint("分享效果和找到肌肤双胞胎")

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: selectedTab == 5 ? "person.fill" : "person")
                }
                .tag(5)
                .accessibilityLabel("我的")
                .accessibilityHint("个人设置和皮肤档案")
        }
        .tint(Color.romanticPink)
    }
}

#Preview {
    ContentView()
}
