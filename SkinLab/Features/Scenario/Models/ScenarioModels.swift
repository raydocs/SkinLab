//
//  ScenarioModels.swift
//  SkinLab
//
//  场景化护肤模型
//  定义不同护肤场景及其针对性建议
//

import Foundation
import SwiftUI

// MARK: - Skin Scenario Enum

/// 皮肤护理场景枚举
/// 用户可根据当前场景获取针对性的护肤建议
enum SkinScenario: String, CaseIterable, Codable, Sendable, Identifiable {
    case office = "办公室"        // 长时间空调、蓝光暴露
    case outdoor = "户外运动"     // 高UV、出汗
    case travel = "长途旅行"      // 干燥机舱、时区变化
    case postMakeup = "浓妆后"    // 深层清洁需求
    case menstrual = "生理期"     // 荷尔蒙变化、敏感
    case stressful = "高压期"     // 熬夜、压力大
    case seasonal = "换季期"      // 温湿度变化
    case recovery = "医美后"      // 修复期特殊护理
    case beach = "海边度假"       // 高UV、海水盐分
    case homeRelax = "居家放松"   // 深层护理时机

    var id: String { rawValue }

    // MARK: - Icon

    /// SF Symbol 图标名称
    var icon: String {
        switch self {
        case .office: return "building.2"
        case .outdoor: return "figure.run"
        case .travel: return "airplane"
        case .postMakeup: return "face.dashed"
        case .menstrual: return "heart.circle"
        case .stressful: return "moon.zzz"
        case .seasonal: return "leaf"
        case .recovery: return "cross.circle"
        case .beach: return "sun.horizon"
        case .homeRelax: return "house"
        }
    }

    // MARK: - Description

    /// 场景详细描述
    var description: String {
        switch self {
        case .office:
            return "长时间待在空调房，面对电脑屏幕蓝光暴露"
        case .outdoor:
            return "户外运动时高紫外线照射，大量出汗"
        case .travel:
            return "长途飞行或旅途中，机舱干燥、时区变化"
        case .postMakeup:
            return "浓妆后需要深层清洁，防止毛孔堵塞"
        case .menstrual:
            return "生理期荷尔蒙变化，皮肤更加敏感"
        case .stressful:
            return "熬夜加班或压力大的时期，皮肤状态不稳定"
        case .seasonal:
            return "季节交替时温湿度变化，皮肤需要适应"
        case .recovery:
            return "医美项目后的修复期，需要特殊护理"
        case .beach:
            return "海边度假时高紫外线加海水盐分侵蚀"
        case .homeRelax:
            return "居家放松时间，适合深层护理和面膜"
        }
    }

    // MARK: - Color

    /// 场景主题颜色
    var color: Color {
        switch self {
        case .office:
            return Color.blue
        case .outdoor:
            return Color.green
        case .travel:
            return Color.cyan
        case .postMakeup:
            return Color.pink
        case .menstrual:
            return Color.red.opacity(0.8)
        case .stressful:
            return Color.purple
        case .seasonal:
            return Color.orange
        case .recovery:
            return Color.mint
        case .beach:
            return Color.yellow
        case .homeRelax:
            return Color.indigo
        }
    }

    // MARK: - Priority Factors

    /// 该场景下最关键的护肤因素
    var priorityFactors: [String] {
        switch self {
        case .office:
            return ["保湿", "抗蓝光", "定时补水"]
        case .outdoor:
            return ["防晒", "控油", "及时清洁"]
        case .travel:
            return ["保湿", "精简护肤", "便携产品"]
        case .postMakeup:
            return ["卸妆", "双重清洁", "修复屏障"]
        case .menstrual:
            return ["舒缓镇静", "温和护理", "抗炎"]
        case .stressful:
            return ["抗氧化", "简化流程", "充足休息"]
        case .seasonal:
            return ["屏障修复", "适应调整", "避免刺激"]
        case .recovery:
            return ["修复", "保湿", "防晒"]
        case .beach:
            return ["防晒", "晒后修复", "盐分清洁"]
        case .homeRelax:
            return ["深层护理", "面膜", "按摩"]
        }
    }

    // MARK: - Duration Hint

    /// 场景建议适用时长提示
    var durationHint: String {
        switch self {
        case .office:
            return "适用于日常工作日"
        case .outdoor:
            return "运动前后各有侧重"
        case .travel:
            return "旅途全程适用"
        case .postMakeup:
            return "卸妆后当晚护理"
        case .menstrual:
            return "经期前后约7天"
        case .stressful:
            return "高压期间持续使用"
        case .seasonal:
            return "换季过渡期2-4周"
        case .recovery:
            return "遵医嘱，通常1-4周"
        case .beach:
            return "度假期间全程"
        case .homeRelax:
            return "每周1-2次深层护理"
        }
    }
}

// MARK: - Scenario Recommendation

/// 场景化护肤建议
/// 包含针对特定场景的完整护肤指导
struct ScenarioRecommendation: Codable, Sendable, Identifiable {
    let id: UUID
    let scenario: SkinScenario
    let summary: String               // 建议概述
    let doList: [String]              // 应该做的
    let dontList: [String]            // 避免做的
    let productTips: [String]         // 产品选择建议
    let ingredientFocus: [String]     // 推荐成分
    let ingredientAvoid: [String]     // 避免成分
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        scenario: SkinScenario,
        summary: String,
        doList: [String],
        dontList: [String],
        productTips: [String],
        ingredientFocus: [String],
        ingredientAvoid: [String],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.scenario = scenario
        self.summary = summary
        self.doList = doList
        self.dontList = dontList
        self.productTips = productTips
        self.ingredientFocus = ingredientFocus
        self.ingredientAvoid = ingredientAvoid
        self.generatedAt = generatedAt
    }
}

// MARK: - Scenario Selection

/// 用户场景选择记录
struct ScenarioSelection: Codable, Sendable, Identifiable {
    let id: UUID
    let scenario: SkinScenario
    let selectedAt: Date
    let notes: String?                // 用户备注

    init(
        id: UUID = UUID(),
        scenario: SkinScenario,
        selectedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.scenario = scenario
        self.selectedAt = selectedAt
        self.notes = notes
    }
}

// MARK: - Scenario Category

/// 场景分类（用于UI分组展示）
enum ScenarioCategory: String, CaseIterable, Sendable {
    case daily = "日常"
    case special = "特殊时期"
    case outdoor = "户外活动"
    case care = "护理时机"

    var scenarios: [SkinScenario] {
        switch self {
        case .daily:
            return [.office, .homeRelax]
        case .special:
            return [.menstrual, .stressful, .seasonal, .recovery]
        case .outdoor:
            return [.outdoor, .travel, .beach]
        case .care:
            return [.postMakeup]
        }
    }

    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .special: return "exclamationmark.circle"
        case .outdoor: return "sun.max"
        case .care: return "sparkles"
        }
    }
}
