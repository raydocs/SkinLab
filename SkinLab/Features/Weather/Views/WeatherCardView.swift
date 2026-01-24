//
//  WeatherCardView.swift
//  SkinLab
//
//  天气卡片视图
//  显示当前天气信息和护肤建议
//

import SwiftUI

// MARK: - Weather Card View

/// 天气信息卡片
/// 展示温度、UV指数、湿度、空气质量及护肤建议
struct WeatherCardView: View {
    let weather: WeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: 天气概览
            headerSection

            // 主要指标网格
            metricsGrid

            // 护肤建议
            skincareTipSection
        }
        .padding()
        .freshGlassCard()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // 天气图标
            ZStack {
                Circle()
                    .fill(weather.condition.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: weather.condition.icon)
                    .font(.system(size: 24))
                    .foregroundColor(weather.condition.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(weather.temperatureDisplay)
                        .font(.skinLabTitle2)
                        .foregroundColor(.skinLabText)

                    Text(weather.condition.displayName)
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSubtext)
                }

                if let location = weather.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(location)
                            .font(.skinLabCaption)
                    }
                    .foregroundColor(.skinLabSubtext)
                }
            }

            Spacer()

            // 肌肤友好度评分
            skinFriendlinessIndicator
        }
    }

    private var skinFriendlinessIndicator: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(friendlinessColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: CGFloat(weather.skinFriendlinessScore) / 100)
                    .stroke(friendlinessColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(weather.skinFriendlinessScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(friendlinessColor)
            }

            Text("肌肤指数")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.skinLabSubtext)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("肌肤指数\(weather.skinFriendlinessScore)分")
    }

    private var friendlinessColor: Color {
        let score = weather.skinFriendlinessScore
        if score >= 70 { return .green }
        if score >= 50 { return .orange }
        return .red
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            uvIndexCard
            humidityCard
            airQualityCard
            temperatureCard
        }
    }

    private var uvIndexCard: some View {
        WeatherMetricCard(
            icon: weather.uvLevel.icon,
            iconColor: weather.uvLevel.color,
            title: "UV 指数",
            value: "\(weather.uvIndex)",
            subtitle: weather.uvLevel.rawValue,
            subtitleColor: weather.uvLevel.color
        )
    }

    private var humidityCard: some View {
        WeatherMetricCard(
            icon: "humidity.fill",
            iconColor: .blue,
            title: "湿度",
            value: weather.humidityDisplay,
            subtitle: weather.humidityLevel,
            subtitleColor: humidityColor
        )
    }

    private var airQualityCard: some View {
        WeatherMetricCard(
            icon: weather.airQuality.icon,
            iconColor: weather.airQuality.color,
            title: "空气质量",
            value: weather.airQuality.rawValue,
            subtitle: weather.airQuality.aqiRange,
            subtitleColor: weather.airQuality.color
        )
    }

    private var temperatureCard: some View {
        WeatherMetricCard(
            icon: temperatureIcon,
            iconColor: temperatureColor,
            title: "体感",
            value: weather.temperatureLevel,
            subtitle: weather.temperatureDisplay,
            subtitleColor: temperatureColor
        )
    }

    private var humidityColor: Color {
        switch weather.humidity {
        case 0..<30: return .orange
        case 30..<50: return .green
        case 50..<70: return .blue
        case 70..<85: return .cyan
        default: return .purple
        }
    }

    private var temperatureIcon: String {
        switch weather.temperature {
        case ..<10: return "thermometer.snowflake"
        case 10..<26: return "thermometer.medium"
        default: return "thermometer.sun.fill"
        }
    }

    private var temperatureColor: Color {
        switch weather.temperature {
        case ..<10: return .blue
        case 10..<18: return .cyan
        case 18..<26: return .green
        case 26..<32: return .orange
        default: return .red
        }
    }

    // MARK: - Skincare Tip Section

    private var skincareTipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.skinLabAccent)
                    .accessibilityHidden(true)
                Text("今日护肤提醒")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            Text(weather.overallSkincareTip)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabAccent.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日护肤提醒：\(weather.overallSkincareTip)")
    }
}

// MARK: - Weather Metric Card

/// 单个天气指标卡片
private struct WeatherMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let subtitleColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            Text(value)
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)

            Text(subtitle)
                .font(.skinLabCaption)
                .foregroundColor(subtitleColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(value)，\(subtitle)")
    }
}

// MARK: - Compact Weather Card

/// 紧凑型天气卡片（用于首页等空间有限场景）
struct CompactWeatherCardView: View {
    let weather: WeatherSnapshot
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 16) {
                // 天气图标和温度
                HStack(spacing: 8) {
                    Image(systemName: weather.condition.icon)
                        .font(.system(size: 20))
                        .foregroundColor(weather.condition.color)

                    Text(weather.temperatureDisplay)
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }

                Divider()
                    .frame(height: 24)

                // 关键指标
                HStack(spacing: 12) {
                    compactMetric(
                        icon: weather.uvLevel.icon,
                        value: "UV \(weather.uvIndex)",
                        color: weather.uvLevel.color
                    )

                    compactMetric(
                        icon: "humidity.fill",
                        value: weather.humidityDisplay,
                        color: .blue
                    )

                    compactMetric(
                        icon: weather.airQuality.icon,
                        value: weather.airQuality.rawValue,
                        color: weather.airQuality.color
                    )
                }

                Spacer()

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.skinLabSubtext)
                }
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
            .skinLabSoftShadow()
        }
        .buttonStyle(.plain)
    }

    private func compactMetric(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabText)
        }
    }
}

// MARK: - Weather Loading Card

/// 天气加载状态卡片
struct WeatherLoadingCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .shimmer()

                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 100, height: 20)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 14)
                        .shimmer()
                }

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 80)
                        .shimmer()
                }
            }
        }
        .padding()
        .freshGlassCard()
    }
}

// MARK: - Weather Error Card

/// 天气获取失败卡片
struct WeatherErrorCardView: View {
    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text("无法获取天气")
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)

            Text(message)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)

            if let onRetry = onRetry {
                Button {
                    onRetry()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("重试")
                    }
                    .font(.skinLabSubheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(LinearGradient.skinLabPrimaryGradient)
                    .cornerRadius(20)
                }
                .accessibilityLabel("重试")
                .accessibilityHint("重新获取天气信息")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .freshGlassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("无法获取天气，\(message)")
    }
}

// MARK: - Shimmer Effect

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview("Weather Card") {
    ScrollView {
        VStack(spacing: 20) {
            WeatherCardView(weather: WeatherSnapshot(
                temperature: 26,
                humidity: 65,
                uvIndex: 7,
                airQuality: .moderate,
                condition: .sunny,
                recordedAt: Date(),
                location: "上海"
            ))

            CompactWeatherCardView(weather: WeatherSnapshot(
                temperature: 26,
                humidity: 65,
                uvIndex: 7,
                airQuality: .moderate,
                condition: .sunny,
                recordedAt: Date(),
                location: "上海"
            )) {
                // Preview action placeholder
            }

            WeatherLoadingCardView()

            WeatherErrorCardView(message: "请检查网络连接或位置权限") {
                // Preview action placeholder
            }
        }
        .padding()
    }
    .background(Color.skinLabBackground)
}

#Preview("Weather - Extreme Conditions") {
    ScrollView {
        VStack(spacing: 20) {
            // High UV, dry, polluted
            WeatherCardView(weather: WeatherSnapshot(
                temperature: 35,
                humidity: 25,
                uvIndex: 11,
                airQuality: .unhealthy,
                condition: .sunny,
                recordedAt: Date(),
                location: "北京"
            ))

            // Cold, humid, foggy
            WeatherCardView(weather: WeatherSnapshot(
                temperature: 5,
                humidity: 85,
                uvIndex: 1,
                airQuality: .unhealthySensitive,
                condition: .foggy,
                recordedAt: Date(),
                location: "成都"
            ))
        }
        .padding()
    }
    .background(Color.skinLabBackground)
}
