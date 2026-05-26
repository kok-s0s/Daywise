import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var priceText = ""
    @State private var purchaseDate = Date()
    @State private var category = "其他"
    @State private var status = ItemStatus.serving
    @State private var soldPriceText = ""
    @State private var soldDate = Date()
    @State private var note = ""

    private let categories = ["数码", "家电", "服饰", "家居", "运动", "美妆", "书籍", "其他"]

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                categorySection
                statusSection
                if status == .sold {
                    soldSection
                }
                noteSection
            }
            .navigationTitle("添加物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveItem() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty || priceText.isEmpty)
                }
            }
        }
    }

    private var basicSection: some View {
        Section("基本信息") {
            HStack {
                Text("名称")
                TextField("物品名称", text: $name)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("价格")
                HStack(spacing: 2) {
                    Text("¥").foregroundStyle(.secondary)
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            DatePicker("购入日期", selection: $purchaseDate, in: ...Date(), displayedComponents: .date)
        }
    }

    private var categorySection: some View {
        Section("分类") {
            Picker("分类", selection: $category) {
                ForEach(categories, id: \.self) { Text($0).tag($0) }
            }
        }
    }

    private var statusSection: some View {
        Section("状态") {
            Picker("状态", selection: $status) {
                ForEach(ItemStatus.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var soldSection: some View {
        Section("出售信息") {
            HStack {
                Text("出售价格")
                HStack(spacing: 2) {
                    Text("¥").foregroundStyle(.secondary)
                    TextField("0.00", text: $soldPriceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            DatePicker("出售日期", selection: $soldDate, in: purchaseDate...Date(), displayedComponents: .date)
        }
    }

    private var noteSection: some View {
        Section("备注") {
            TextField("选填", text: $note, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
        }
    }

    private func saveItem() {
        guard let price = Double(priceText), price > 0 else { return }
        let soldPrice = status == .sold ? Double(soldPriceText) : nil
        let item = Item(
            name: name,
            price: price,
            purchaseDate: purchaseDate,
            category: category,
            status: status,
            soldPrice: soldPrice,
            soldDate: status == .sold ? soldDate : nil,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(item)
        dismiss()
    }
}
