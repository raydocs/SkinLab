import XCTest

final class AnalysisFlowUITests: SkinLabUITests {
    // MARK: - Camera Access Tests

    func test_analysisScreen_whenOpened_showsCameraPrompt() {
        tapButton("startAnalysisButton")

        XCTAssertTrue(waitForElement(app.staticTexts["皮肤分析"]))
        takeScreenshot(name: "analysis_screen_opened")
    }

    func test_analysisScreen_whenPhotoSelected_showsProcessingIndicator() {
        tapButton("startAnalysisButton")
        tapButton("selectPhotoButton")

        let processingIndicator = app.activityIndicators["processingIndicator"]
        XCTAssertTrue(waitForElement(processingIndicator, timeout: 3))
    }

    // MARK: - Analysis Results Tests

    func test_analysisResults_whenCompleted_showsOverallScore() {
        performMockAnalysis()

        let scoreLabel = app.staticTexts["overallScoreLabel"]
        XCTAssertTrue(waitForElement(scoreLabel, timeout: 10))
        takeScreenshot(name: "analysis_results_score")
    }

    func test_analysisResults_whenCompleted_showsSkinTypeInfo() {
        performMockAnalysis()

        let skinTypeSection = app.otherElements["skinTypeSection"]
        XCTAssertTrue(waitForElement(skinTypeSection, timeout: 10))
    }

    func test_analysisResults_whenCompleted_showsIssueBreakdown() {
        performMockAnalysis()

        let issueSection = app.otherElements["issueBreakdownSection"]
        XCTAssertTrue(waitForElement(issueSection, timeout: 10))

        assertTextExists("毛孔")
        assertTextExists("皱纹")
        assertTextExists("色斑")
    }

    func test_analysisResults_whenCompleted_showsRecommendations() {
        performMockAnalysis()

        swipeUp()

        let recommendationsSection = app.otherElements["recommendationsSection"]
        XCTAssertTrue(waitForElement(recommendationsSection))
        takeScreenshot(name: "analysis_recommendations")
    }

    // MARK: - Region Analysis Tests

    func test_regionAnalysis_whenTapped_showsDetailedView() {
        performMockAnalysis()

        let foreheadRegion = app.buttons["foreheadRegion"]
        if waitForElement(foreheadRegion, timeout: 5) {
            foreheadRegion.tap()

            let regionDetailView = app.otherElements["regionDetailView"]
            XCTAssertTrue(waitForElement(regionDetailView))
            takeScreenshot(name: "region_detail_forehead")
        }
    }

    // MARK: - Share & Save Tests

    func test_analysisResults_whenShareTapped_showsShareSheet() {
        performMockAnalysis()

        tapButton("shareResultsButton")

        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(waitForElement(shareSheet, timeout: 5))
    }

    func test_analysisResults_whenSaveTapped_showsConfirmation() {
        performMockAnalysis()

        tapButton("saveResultsButton")

        assertTextExists("已保存")
    }

    // MARK: - History Tests

    func test_analysisHistory_whenOpened_showsPreviousAnalyses() {
        tapButton("historyTabButton")

        let historyList = app.collectionViews["analysisHistoryList"]
        XCTAssertTrue(waitForElement(historyList))
        takeScreenshot(name: "analysis_history")
    }

    func test_analysisHistory_whenItemTapped_showsDetailView() {
        tapButton("historyTabButton")

        let historyList = app.collectionViews["analysisHistoryList"]
        if waitForElement(historyList) {
            let firstItem = historyList.cells.firstMatch
            if firstItem.exists {
                firstItem.tap()

                let detailView = app.otherElements["analysisDetailView"]
                XCTAssertTrue(waitForElement(detailView))
            }
        }
    }

    // MARK: - Error Handling Tests

    func test_analysis_whenNetworkError_showsRetryOption() {
        app.launchEnvironment["MOCK_NETWORK_ERROR"] = "true"
        app.launch()

        tapButton("startAnalysisButton")
        tapButton("selectPhotoButton")

        waitForLoadingToComplete(timeout: 15)

        let retryButton = app.buttons["retryAnalysisButton"]
        XCTAssertTrue(waitForElement(retryButton, timeout: 10))
        takeScreenshot(name: "analysis_network_error")
    }

    func test_analysis_whenInvalidImage_showsErrorMessage() {
        app.launchEnvironment["MOCK_INVALID_IMAGE"] = "true"
        app.launch()

        tapButton("startAnalysisButton")
        tapButton("selectPhotoButton")

        assertTextExists("图片无效")
    }

    // MARK: - Private Helpers

    private func performMockAnalysis() {
        app.launchEnvironment["MOCK_ANALYSIS_RESULT"] = "true"
        app.launch()

        tapButton("startAnalysisButton")
        tapButton("selectPhotoButton")

        waitForLoadingToComplete(timeout: 15)
    }
}
