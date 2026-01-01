import SwiftUI
import SwiftData

struct ProductPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProducts: [String]
    @State private var searchText = ""

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

    var body: some View {
        NavigationStack {
            List {
                if products.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 36))
                            .foregroundColor(.skinLabSubtext)
                        Text("暂无产品数据")
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                        Text("请先在产品库中导入或添加产品")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredProducts, id: \.id) { product in
                        Button {
                            toggleSelection(for: product)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.skinLabBody)
                                        .foregroundColor(.skinLabText)
                                    Text(product.brand)
                                        .font(.skinLabCaption)
                                        .foregroundColor(.skinLabSubtext)
                                }
                                Spacer()
                                if selectedProducts.contains(product.name) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.skinLabPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "搜索产品")
            .navigationTitle("选择产品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.skinLabPrimary)
                }
            }
        }
    }

    private func toggleSelection(for product: ProductRecord) {
        let name = product.name
        if let index = selectedProducts.firstIndex(of: name) {
            selectedProducts.remove(at: index)
        } else {
            selectedProducts.append(name)
        }
    }
}
