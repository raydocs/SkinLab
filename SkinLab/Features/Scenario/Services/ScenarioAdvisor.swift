import Foundation

/// 场景化护肤顾问
/// 根据场景、用户肤质和当前皮肤状态生成个性化建议
struct ScenarioAdvisor {
    // MARK: - Main Generation Method

    /// 生成场景化护肤建议
    /// - Parameters:
    ///   - scenario: 用户选择的护肤场景
    ///   - profile: 用户档案（包含肤质、关注点等）
    ///   - currentAnalysis: 最近的皮肤分析结果（可选）
    /// - Returns: 针对该场景的完整护肤建议
    func generateRecommendation(
        scenario: SkinScenario,
        profile: UserProfile,
        currentAnalysis: SkinAnalysis?
    ) -> ScenarioRecommendation {
        // 获取场景基础建议
        let baseDoList = generateDoList(for: scenario, profile: profile)
        let baseDontList = generateDontList(for: scenario, profile: profile)
        let productTips = generateProductTips(for: scenario, profile: profile)
        let (ingredientFocus, ingredientAvoid) = generateIngredientGuidance(
            for: scenario,
            profile: profile,
            currentAnalysis: currentAnalysis
        )

        // 生成概述
        let summary = generateSummary(
            scenario: scenario,
            profile: profile,
            currentAnalysis: currentAnalysis
        )

        return ScenarioRecommendation(
            scenario: scenario,
            summary: summary,
            doList: baseDoList,
            dontList: baseDontList,
            productTips: productTips,
            ingredientFocus: ingredientFocus,
            ingredientAvoid: ingredientAvoid
        )
    }

    // MARK: - Summary Generation

    /// 生成建议概述
    private func generateSummary(
        scenario: SkinScenario,
        profile: UserProfile,
        currentAnalysis: SkinAnalysis?
    ) -> String {
        let skinTypeDesc = profile.skinType?.displayName ?? "您的"
        let scenarioName = scenario.rawValue

        var summary = "\(skinTypeDesc)肤质在\(scenarioName)场景下，"

        // 根据场景添加核心建议
        switch scenario {
        case .office:
            summary += "需注意保湿补水和抗蓝光防护。"
        case .outdoor:
            summary += "防晒是第一要务，运动后及时清洁。"
        case .travel:
            summary += "建议精简护肤步骤，重点保湿。"
        case .postMakeup:
            summary += "温和彻底卸妆是关键，避免过度清洁。"
        case .menstrual:
            summary += "皮肤较敏感，建议简化流程并加强舒缓。"
        case .stressful:
            summary += "减少护肤步骤，专注抗氧化和修复。"
        case .seasonal:
            summary += "需要帮助皮肤适应温湿度变化。"
        case .recovery:
            summary += "修复期需遵医嘱，以保湿修复为主。"
        case .beach:
            summary += "高倍防晒必备，晒后及时修复。"
        case .homeRelax:
            summary += "是深层护理的好时机。"
        }

        // 如果有当前分析，添加个性化提示
        if let analysis = currentAnalysis {
            if analysis.issues.redness >= 5 {
                summary += "目前泛红较明显，建议加强舒缓。"
            }
            if analysis.issues.acne >= 5 {
                summary += "注意控油抗炎。"
            }
        }

        return summary
    }

    // MARK: - Do List Generation

    /// 生成"应该做"列表
    private func generateDoList(
        for scenario: SkinScenario,
        profile: UserProfile
    ) -> [String] {
        var doList: [String] = []

        // 场景特定建议
        switch scenario {
        case .office:
            doList.append("每2-3小时使用保湿喷雾补水")
            doList.append("使用含抗蓝光成分的护肤品")
            doList.append("中午补涂防晒（如靠窗）")
            doList.append("定时起身活动促进血液循环")

        case .outdoor:
            doList.append("出门前30分钟涂抹SPF50+防晒")
            doList.append("每2小时补涂防晒")
            doList.append("运动后尽快清洁")
            doList.append("使用抗氧化精华")

        case .travel:
            doList.append("随身携带保湿喷雾")
            doList.append("飞机上敷保湿面膜")
            doList.append("多喝水保持身体水分")
            doList.append("使用旅行装避免携带新产品")

        case .postMakeup:
            doList.append("使用卸妆油/膏彻底卸妆")
            doList.append("二次使用温和洁面")
            doList.append("卸妆后立即保湿")
            doList.append("使用修复类精华")

        case .menstrual:
            doList.append("使用温和低刺激产品")
            doList.append("加强保湿")
            doList.append("敷舒缓面膜")
            doList.append("保证充足睡眠")

        case .stressful:
            doList.append("简化护肤步骤")
            doList.append("使用抗氧化精华")
            doList.append("保证充足睡眠")
            doList.append("适当运动释放压力")

        case .seasonal:
            doList.append("逐步调整护肤品")
            doList.append("加强屏障修复")
            doList.append("使用含神经酰胺产品")
            doList.append("观察皮肤反应及时调整")

        case .recovery:
            doList.append("严格遵医嘱护理")
            doList.append("使用医用修复产品")
            doList.append("物理防晒为主")
            doList.append("保持皮肤清洁湿润")

        case .beach:
            doList.append("使用防水防汗SPF50+PA++++防晒")
            doList.append("每小时补涂防晒")
            doList.append("回到室内后清洁盐分")
            doList.append("晒后使用芦荟凝胶舒缓")

        case .homeRelax:
            doList.append("深层清洁（每周1-2次）")
            doList.append("敷精华面膜")
            doList.append("做面部按摩")
            doList.append("使用高效能精华")
        }

        // 根据肤质添加额外建议
        if let skinType = profile.skinType {
            switch skinType {
            case .dry:
                if !doList.contains(where: { $0.contains("保湿") }) {
                    doList.append("额外加强保湿")
                }
            case .oily:
                doList.append("选择清爽质地产品")
            case .combination:
                doList.append("T区和两颊分区护理")
            case .sensitive:
                doList.append("先在耳后测试新产品")
            }
        }

        return doList
    }

    // MARK: - Don't List Generation

    /// 生成"避免做"列表
    private func generateDontList(
        for scenario: SkinScenario,
        profile: UserProfile
    ) -> [String] {
        var dontList: [String] = []

        switch scenario {
        case .office:
            dontList.append("不要长时间不补水")
            dontList.append("避免用手摸脸")
            dontList.append("不要忽视室内防晒")

        case .outdoor:
            dontList.append("不要使用厚重油腻产品")
            dontList.append("避免在阳光最强时外出")
            dontList.append("不要忘记补涂防晒")

        case .travel:
            dontList.append("不要尝试新产品")
            dontList.append("避免过度清洁")
            dontList.append("不要熬夜打乱作息")

        case .postMakeup:
            dontList.append("不要使用磨砂或去角质")
            dontList.append("避免使用高浓度酸类")
            dontList.append("不要用力揉搓皮肤")

        case .menstrual:
            dontList.append("避免使用刺激性酸类")
            dontList.append("不要尝试新产品")
            dontList.append("不要过度清洁")

        case .stressful:
            dontList.append("不要增加护肤步骤")
            dontList.append("避免高活性成分")
            dontList.append("不要熬夜")

        case .seasonal:
            dontList.append("不要突然更换全套护肤品")
            dontList.append("避免使用刺激性产品")
            dontList.append("不要忽视皮肤变化信号")

        case .recovery:
            dontList.append("不要擅自使用功效产品")
            dontList.append("避免化妆")
            dontList.append("不要暴晒")
            dontList.append("不要去角质")

        case .beach:
            dontList.append("不要使用含酒精产品")
            dontList.append("避免中午阳光直射")
            dontList.append("不要忽视嘴唇和耳朵防晒")

        case .homeRelax:
            dontList.append("不要过度护理")
            dontList.append("避免同时叠加多种活性成分")
            dontList.append("不要忽视颈部护理")
        }

        // 根据敏感肤质添加额外警告
        if profile.skinType == .sensitive {
            if !dontList.contains(where: { $0.contains("刺激") }) {
                dontList.append("避免任何刺激性成分")
            }
        }

        // 怀孕/哺乳期特别注意
        if profile.pregnancyStatus.requiresSpecialCare {
            dontList.append("避免使用视黄醇/A酸类成分")
            dontList.append("不要使用水杨酸（高浓度）")
        }

        return dontList
    }

    // MARK: - Product Tips Generation

    /// 生成产品选择建议
    private func generateProductTips(
        for scenario: SkinScenario,
        profile: UserProfile
    ) -> [String] {
        var tips: [String] = []

        switch scenario {
        case .office:
            tips.append("选择轻薄保湿喷雾")
            tips.append("使用含抗蓝光成分的日霜")
            tips.append("备一支护手霜")

        case .outdoor:
            tips.append("选择防水防汗型防晒")
            tips.append("使用轻薄质地的保湿产品")
            tips.append("携带防晒喷雾便于补涂")

        case .travel:
            tips.append("准备旅行分装瓶")
            tips.append("带一款多效面霜")
            tips.append("面膜选择独立包装")

        case .postMakeup:
            tips.append("选择温和的卸妆油或膏")
            tips.append("使用氨基酸洁面")
            tips.append("备修复面霜或精华")

        case .menstrual:
            tips.append("使用舒缓镇静面膜")
            tips.append("选择无香精产品")
            tips.append("考虑使用积雪草产品")

        case .stressful:
            tips.append("选择抗氧化精华")
            tips.append("使用修复类晚霜")
            tips.append("考虑使用香薰辅助放松")

        case .seasonal:
            tips.append("准备适合新季节的产品")
            tips.append("选择含神经酰胺的屏障修复产品")
            tips.append("使用温和的换季过渡产品")

        case .recovery:
            tips.append("使用医生推荐的医用护肤品")
            tips.append("选择物理防晒产品")
            tips.append("使用无添加的保湿产品")

        case .beach:
            tips.append("选择SPF50+ PA++++防晒")
            tips.append("准备晒后修复凝胶")
            tips.append("使用防水眼霜")

        case .homeRelax:
            tips.append("选择高效精华面膜")
            tips.append("准备按摩油或精华")
            tips.append("使用功效型精华（如美白、抗老）")
        }

        // 根据预算调整建议
        switch profile.budgetLevel {
        case .economy:
            tips.append("可选择药房品牌性价比产品")
        case .luxury, .noBudget:
            tips.append("可考虑专业线或贵妇级产品")
        default:
            break
        }

        return tips
    }

    // MARK: - Ingredient Guidance

    /// 生成成分指导
    private func generateIngredientGuidance(
        for scenario: SkinScenario,
        profile: UserProfile,
        currentAnalysis: SkinAnalysis?
    ) -> (focus: [String], avoid: [String]) {
        var focus: [String] = []
        var avoid: [String] = []

        switch scenario {
        case .office:
            focus = ["透明质酸", "烟酰胺", "维生素E", "积雪草"]
            avoid = ["高浓度酒精"]

        case .outdoor:
            focus = ["维生素C", "维生素E", "白藜芦醇", "绿茶提取物"]
            avoid = ["光敏成分（柠檬精油等）", "视黄醇（白天）"]

        case .travel:
            focus = ["透明质酸", "甘油", "角鲨烷"]
            avoid = ["新接触的成分"]

        case .postMakeup:
            focus = ["神经酰胺", "泛醇", "角鲨烷", "尿囊素"]
            avoid = ["果酸", "水杨酸", "视黄醇", "磨砂颗粒"]

        case .menstrual:
            focus = ["积雪草", "洋甘菊", "尿囊素", "芦荟"]
            avoid = ["果酸", "水杨酸", "视黄醇", "酒精"]

        case .stressful:
            focus = ["烟酰胺", "维生素C", "阿魏酸", "辅酶Q10"]
            avoid = ["高浓度酸类", "强效活性成分"]

        case .seasonal:
            focus = ["神经酰胺", "胆固醇", "脂肪酸", "透明质酸"]
            avoid = ["新产品成分", "刺激性成分"]

        case .recovery:
            focus = ["泛醇", "尿囊素", "透明质酸", "神经酰胺"]
            avoid = ["果酸", "水杨酸", "视黄醇", "香精", "酒精", "色素"]

        case .beach:
            focus = ["氧化锌", "二氧化钛", "维生素E", "芦荟"]
            avoid = ["光敏性成分", "酒精", "香料"]

        case .homeRelax:
            focus = ["视黄醇", "维生素C", "果酸（适量）", "多肽"]
            avoid = []
        }

        // 根据肤质调整
        if let skinType = profile.skinType {
            switch skinType {
            case .sensitive:
                // 敏感肌避免的成分
                avoid.append(contentsOf: ["酒精", "香精", "人工色素"].filter { !avoid.contains($0) })
                focus = focus.filter { !["果酸", "视黄醇"].contains($0) }
                focus.append("积雪草")
                focus.append("洋甘菊")

            case .oily:
                focus.append("烟酰胺")
                focus.append("水杨酸（低浓度）")

            case .dry:
                focus.append("角鲨烷")
                focus.append("乳木果油")
                avoid.append("高浓度酒精")

            case .combination:
                focus.append("烟酰胺")
            }
        }

        // 根据当前皮肤状态调整
        if let analysis = currentAnalysis {
            if analysis.issues.redness >= 5 {
                focus.append("积雪草")
                focus.append("甘草酸二钾")
                avoid.append("刺激性成分")
            }
            if analysis.issues.acne >= 5 {
                focus.append("茶树精油")
                focus.append("水杨酸")
            }
        }

        // 去重
        focus = Array(Set(focus))
        avoid = Array(Set(avoid))

        return (focus, avoid)
    }
}
