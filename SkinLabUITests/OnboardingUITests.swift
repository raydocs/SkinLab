import XCTest

final class OnboardingUITests: SkinLabUITests {
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--reset-onboarding")
    }

    // MARK: - Welcome Screen Tests

    func test_onboarding_whenFirstLaunch_showsWelcomeScreen() {
        assertTextExists("欢迎使用 SkinLab")
        takeScreenshot(name: "onboarding_welcome")
    }

    func test_onboarding_welcomeScreen_showsAppLogo() {
        let logo = app.images["appLogo"]
        XCTAssertTrue(waitForElement(logo))
    }

    func test_onboarding_welcomeScreen_showsGetStartedButton() {
        let getStartedButton = app.buttons["getStartedButton"]
        XCTAssertTrue(waitForElement(getStartedButton))
    }

    // MARK: - Feature Introduction Tests

    func test_onboarding_whenGetStartedTapped_showsFeatureIntro() {
        tapButton("getStartedButton")

        assertTextExists("AI 皮肤分析")
        takeScreenshot(name: "onboarding_feature_intro")
    }

    func test_onboarding_featureIntro_canSwipeThroughPages() {
        tapButton("getStartedButton")

        swipeLeft()
        assertTextExists("成分扫描")
        takeScreenshot(name: "onboarding_ingredient_scanner")

        swipeLeft()
        assertTextExists("效果追踪")
        takeScreenshot(name: "onboarding_effect_tracking")

        swipeLeft()
        assertTextExists("个性化推荐")
        takeScreenshot(name: "onboarding_personalized_recommendation")
    }

    func test_onboarding_featureIntro_showsPageIndicator() {
        tapButton("getStartedButton")

        let pageIndicator = app.pageIndicators.firstMatch
        XCTAssertTrue(pageIndicator.exists)
    }

    func test_onboarding_featureIntro_skipButtonSkipsToEnd() {
        tapButton("getStartedButton")
        tapButton("skipButton")

        assertTextExists("隐私设置")
    }

    // MARK: - Privacy Settings Tests

    func test_onboarding_privacySettings_showsDataCollectionInfo() {
        navigateToPrivacySettings()

        assertTextExists("数据收集")
        assertTextExists("我们如何使用您的数据")
        takeScreenshot(name: "onboarding_privacy_settings")
    }

    func test_onboarding_privacySettings_showsPrivacyToggles() {
        navigateToPrivacySettings()

        let analyticsToggle = app.switches["analyticsToggle"]
        let crashReportingToggle = app.switches["crashReportingToggle"]

        XCTAssertTrue(waitForElement(analyticsToggle))
        XCTAssertTrue(waitForElement(crashReportingToggle))
    }

    func test_onboarding_privacySettings_canToggleOptions() {
        navigateToPrivacySettings()

        let analyticsToggle = app.switches["analyticsToggle"]
        if waitForElement(analyticsToggle) {
            let initialValue = analyticsToggle.value as? String
            analyticsToggle.tap()
            let newValue = analyticsToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue)
        }
    }

    // MARK: - Skin Profile Setup Tests

    func test_onboarding_skinProfile_showsSkinTypeSelection() {
        navigateToSkinProfileSetup()

        assertTextExists("您的肤质类型")

        assertTextExists("干性")
        assertTextExists("油性")
        assertTextExists("混合性")
        assertTextExists("敏感性")
        assertTextExists("中性")
        takeScreenshot(name: "onboarding_skin_type")
    }

    func test_onboarding_skinProfile_canSelectSkinType() {
        navigateToSkinProfileSetup()

        let oilySkinButton = app.buttons["油性"]
        if waitForElement(oilySkinButton) {
            oilySkinButton.tap()
            XCTAssertTrue(oilySkinButton.isSelected)
        }
    }

    func test_onboarding_skinProfile_showsConcernsSelection() {
        navigateToSkinProfileSetup()
        selectSkinType("混合性")
        tapButton("nextButton")

        assertTextExists("您的皮肤问题")
        assertTextExists("毛孔粗大")
        assertTextExists("细纹")
        assertTextExists("暗沉")
        assertTextExists("痘痘")
        takeScreenshot(name: "onboarding_skin_concerns")
    }

    func test_onboarding_skinProfile_canSelectMultipleConcerns() {
        navigateToSkinProfileSetup()
        selectSkinType("混合性")
        tapButton("nextButton")

        tapButton("毛孔粗大")
        tapButton("细纹")

        let selectedCount = app.buttons.matching(NSPredicate(format: "isSelected == true")).count
        XCTAssertEqual(selectedCount, 2)
    }

    func test_onboarding_skinProfile_showsAgeRangeSelection() {
        navigateToSkinProfileSetup()
        selectSkinType("混合性")
        tapButton("nextButton")
        tapButton("毛孔粗大")
        tapButton("nextButton")

        assertTextExists("您的年龄段")
        takeScreenshot(name: "onboarding_age_range")
    }

    // MARK: - Completion Tests

    func test_onboarding_whenCompleted_showsMainScreen() {
        completeOnboarding()

        let mainTabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(mainTabBar, timeout: 5))
        takeScreenshot(name: "onboarding_completed_main_screen")
    }

    func test_onboarding_afterCompletion_doesNotShowAgain() {
        completeOnboarding()

        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-onboarding" }
        app.launch()

        let welcomeText = app.staticTexts["欢迎使用 SkinLab"]
        XCTAssertFalse(welcomeText.exists)
    }

    // MARK: - Accessibility Tests

    func test_onboarding_allElements_haveAccessibilityLabels() {
        let getStartedButton = app.buttons["getStartedButton"]
        XCTAssertTrue(waitForElement(getStartedButton))
        XCTAssertNotNil(getStartedButton.label)
        XCTAssertFalse(getStartedButton.label.isEmpty)
    }

    // MARK: - Private Helpers

    private func navigateToPrivacySettings() {
        tapButton("getStartedButton")
        tapButton("skipButton")
    }

    private func navigateToSkinProfileSetup() {
        navigateToPrivacySettings()
        tapButton("continueButton")
    }

    private func selectSkinType(_ type: String) {
        let skinTypeButton = app.buttons[type]
        if waitForElement(skinTypeButton) {
            skinTypeButton.tap()
        }
    }

    private func completeOnboarding() {
        tapButton("getStartedButton")
        tapButton("skipButton")
        tapButton("continueButton")
        selectSkinType("混合性")
        tapButton("nextButton")
        tapButton("毛孔粗大")
        tapButton("nextButton")
        tapButton("18-25")
        tapButton("completeButton")
    }

    private func swipeLeft() {
        app.swipeLeft()
    }
}
