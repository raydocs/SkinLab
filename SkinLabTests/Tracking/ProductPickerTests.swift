// SkinLabTests/Tracking/ProductPickerTests.swift
import XCTest

@testable import SkinLab

final class ProductPickerTests: XCTestCase {

    // MARK: - Selection Logic Tests

    func testToggleSelection_addsProductWhenNotSelected() {
        var selectedProducts: [String] = []
        let productName = "Test Product"

        // Simulate toggle selection
        if let index = selectedProducts.firstIndex(of: productName) {
            selectedProducts.remove(at: index)
        } else {
            selectedProducts.append(productName)
        }

        XCTAssertEqual(selectedProducts.count, 1)
        XCTAssertTrue(selectedProducts.contains(productName))
    }

    func testToggleSelection_removesProductWhenSelected() {
        var selectedProducts: [String] = ["Test Product", "Another Product"]
        let productName = "Test Product"

        // Simulate toggle selection
        if let index = selectedProducts.firstIndex(of: productName) {
            selectedProducts.remove(at: index)
        } else {
            selectedProducts.append(productName)
        }

        XCTAssertEqual(selectedProducts.count, 1)
        XCTAssertFalse(selectedProducts.contains(productName))
        XCTAssertTrue(selectedProducts.contains("Another Product"))
    }

    func testMultipleSelection_allowsMultipleProducts() {
        var selectedProducts: [String] = []

        // Add multiple products
        selectedProducts.append("Product A")
        selectedProducts.append("Product B")
        selectedProducts.append("Product C")

        XCTAssertEqual(selectedProducts.count, 3)
        XCTAssertTrue(selectedProducts.contains("Product A"))
        XCTAssertTrue(selectedProducts.contains("Product B"))
        XCTAssertTrue(selectedProducts.contains("Product C"))
    }

    func testClearAll_removesAllSelections() {
        var selectedProducts: [String] = ["Product A", "Product B", "Product C"]

        selectedProducts.removeAll()

        XCTAssertTrue(selectedProducts.isEmpty)
        XCTAssertEqual(selectedProducts.count, 0)
    }

    // MARK: - Search/Filter Logic Tests

    func testFilterProducts_byName() {
        let products = [
            MockProduct(name: "B5 Repair Cream", brand: "La Roche-Posay"),
            MockProduct(name: "Moisturizing Lotion", brand: "CeraVe"),
            MockProduct(name: "Sunscreen SPF50", brand: "Neutrogena"),
        ]

        let query = "Cream"
        let filtered = products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query)
        }

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "B5 Repair Cream")
    }

    func testFilterProducts_byBrand() {
        let products = [
            MockProduct(name: "B5 Repair Cream", brand: "La Roche-Posay"),
            MockProduct(name: "Moisturizing Lotion", brand: "CeraVe"),
            MockProduct(name: "Cleanser", brand: "CeraVe"),
        ]

        let query = "CeraVe"
        let filtered = products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query)
        }

        XCTAssertEqual(filtered.count, 2)
    }

    func testFilterProducts_caseInsensitive() {
        let products = [
            MockProduct(name: "B5 REPAIR CREAM", brand: "La Roche-Posay"),
        ]

        let query = "repair cream"
        let filtered = products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query)
        }

        XCTAssertEqual(filtered.count, 1)
    }

    func testFilterProducts_emptyQuery_returnsAll() {
        let products = [
            MockProduct(name: "Product A", brand: "Brand A"),
            MockProduct(name: "Product B", brand: "Brand B"),
        ]

        let query = ""
        let filtered: [MockProduct]
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = products
        } else {
            filtered = products.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.brand.localizedCaseInsensitiveContains(query)
            }
        }

        XCTAssertEqual(filtered.count, 2)
    }

    func testFilterProducts_noMatch_returnsEmpty() {
        let products = [
            MockProduct(name: "Product A", brand: "Brand A"),
            MockProduct(name: "Product B", brand: "Brand B"),
        ]

        let query = "NonExistent"
        let filtered = products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query)
        }

        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - CheckIn Integration Tests

    func testCheckIn_withSelectedProducts() {
        let sessionId = UUID()
        let selectedProducts = ["Product A", "Product B"]

        let checkIn = CheckIn(
            sessionId: sessionId,
            day: 7,
            captureDate: Date(),
            photoPath: "/path/to/photo.jpg",
            analysisId: UUID(),
            usedProducts: selectedProducts,
            notes: nil,
            feeling: .same
        )

        XCTAssertEqual(checkIn.usedProducts.count, 2)
        XCTAssertTrue(checkIn.usedProducts.contains("Product A"))
        XCTAssertTrue(checkIn.usedProducts.contains("Product B"))
    }

    func testCheckIn_withEmptyProducts() {
        let sessionId = UUID()

        let checkIn = CheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: Date(),
            photoPath: nil,
            analysisId: nil,
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        XCTAssertTrue(checkIn.usedProducts.isEmpty)
    }

    // MARK: - Selection Count Tests

    func testSelectionCount_zero() {
        let selectedProducts: [String] = []
        XCTAssertEqual(selectedProducts.count, 0)
    }

    func testSelectionCount_multiple() {
        let selectedProducts = ["A", "B", "C", "D", "E"]
        XCTAssertEqual(selectedProducts.count, 5)
    }

    // MARK: - Duplicate Prevention Tests

    func testDuplicatePrevention_doesNotAddDuplicate() {
        var selectedProducts: [String] = ["Product A"]
        let productName = "Product A"

        // Check if already selected before adding
        if !selectedProducts.contains(productName) {
            selectedProducts.append(productName)
        }

        XCTAssertEqual(selectedProducts.count, 1)
    }
}

// MARK: - Mock Types for Testing

private struct MockProduct {
    let name: String
    let brand: String
}
