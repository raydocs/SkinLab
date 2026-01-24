import SwiftUI
import SwiftData

struct ProductPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProducts: [String]
    @State private var searchText = ""
    @State private var showScanner = false

    @Query(sort: [SortDescriptor(\ProductRecord.updatedAt, order: .reverse)])
    private var products: [ProductRecord]

    private var filteredProducts: [ProductRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.brand.localizedCaseInsensitiveContains(query)
        }
    }

    /// Count of currently selected products
    private var selectionCount: Int {
        selectedProducts.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selection summary bar
                if selectionCount > 0 {
                    HStack {
                        Text("已选择 \(selectionCount) 个产品")
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabText)

                        Spacer()

                        Button("清除全部") {
                            selectedProducts.removeAll()
                        }
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabPrimary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.skinLabPrimary.opacity(0.08))
                }

                List {
                    if products.isEmpty {
                        emptyStateView
                    } else {
                        // Add new product button at top
                        Section {
                            Button {
                                showScanner = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.skinLabPrimary.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.skinLabPrimary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("添加新产品")
                                            .font(.skinLabBody)
                                            .foregroundColor(.skinLabPrimary)
                                        Text("扫描成分表导入产品")
                                            .font(.skinLabCaption)
                                            .foregroundColor(.skinLabSubtext)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.skinLabSubtext)
                                }
                            }
                        }

                        // Product list
                        Section {
                            if filteredProducts.isEmpty && !searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.title2)
                                            .foregroundColor(.skinLabSubtext)
                                        Text("未找到匹配的产品")
                                            .font(.skinLabSubheadline)
                                            .foregroundColor(.skinLabSubtext)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                            } else {
                                ForEach(filteredProducts, id: \.id) { product in
                                    ProductSelectionRow(
                                        product: product,
                                        isSelected: selectedProducts.contains(product.name),
                                        onTap: { toggleSelection(for: product) }
                                    )
                                }
                            }
                        } header: {
                            if !products.isEmpty {
                                Text("产品库 (\(products.count))")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $searchText, prompt: "搜索产品名称或品牌")
            .navigationTitle("选择产品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.skinLabPrimary)
                }
            }
            .sheet(isPresented: $showScanner) {
                IngredientScannerFullView()
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.skinLabPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "shippingbox")
                    .font(.system(size: 40))
                    .foregroundColor(.skinLabPrimary.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("暂无产品数据")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Text("扫描产品成分表来添加你的护肤产品")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)
            }

            Button {
                showScanner = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "barcode.viewfinder")
                    Text("扫描添加产品")
                }
                .font(.skinLabSubheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.skinLabPrimary)
                .cornerRadius(24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func toggleSelection(for product: ProductRecord) {
        let name = product.name
        if let index = selectedProducts.firstIndex(of: name) {
            selectedProducts.remove(at: index)
        } else {
            selectedProducts.append(name)
            // Track product added
            AnalyticsEvents.productAdded(
                name: product.name,
                brand: product.brand,
                source: .manual
            )
            // Track first product added for activation funnel
            FunnelTracker.shared.trackFirstProductAdded(
                productName: product.name,
                source: "manual"
            )
        }
    }
}

// MARK: - Product Selection Row
private struct ProductSelectionRow: View {
    let product: ProductRecord
    let isSelected: Bool
    let onTap: () -> Void

    private var category: ProductCategory? {
        ProductCategory(rawValue: product.categoryRaw)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.skinLabPrimary.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: category?.icon ?? "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .skinLabPrimary : .skinLabSubtext)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(product.brand)
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)

                        if let category = category {
                            Text("·")
                                .foregroundColor(.skinLabSubtext)
                            Text(category.displayName)
                                .font(.skinLabCaption)
                                .foregroundColor(.skinLabSubtext)
                        }
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .skinLabPrimary : .gray.opacity(0.3))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProductPickerView(selectedProducts: .constant(["Test Product"]))
}
