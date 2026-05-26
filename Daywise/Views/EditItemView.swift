import SwiftUI

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: Item

    @State private var name: String
    @State private var priceText: String
    @State private var purchaseDate: Date
    @State private var category: String
    @State private var status: ItemStatus
    @State private var soldPriceText: String
    @State private var soldDate: Date
    @State private var note: String

    private let categories = ["数码", "家电", "服饰", "家居", "运动", "美妆", "书籍", "其他"]

    init(item: Item) {
        self.item = item
        _name = State(initialValue: item.name)
        _priceText = State(initialValue: String(format: "%.2f", item.price))
        _purchaseDate = State(initialValue: item.purchaseDate)
        _category = State(initialValue: item.category)
        _status = State(initialValue: item.status)
        _soldPriceText = State(initialValue: item.soldPrice.map { String(format: "%.2f", $0) } ?? "")
        _soldDate = State(initialValue: item.soldDate ?? Date())
        _note = State(initialValue: item.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("状态") {
                    Picker("状态", selection: $status) {
                        ForEach(ItemStatus.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if status == .sold {
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

                Section("备注") {
                    TextField("选填", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("编辑物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { applyChanges() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty || priceText.isEmpty)
                }
            }
        }
    }

    private func applyChanges() {
        guard let price = Double(priceText), price > 0 else { return }
        item.name = name
        item.price = price
        item.purchaseDate = purchaseDate
        item.category = category
        item.status = status
        item.soldPrice = status == .sold ? Double(soldPriceText) : nil
        item.soldDate = status == .sold ? soldDate : nil
        item.note = note.isEmpty ? nil : note
        dismiss()
    }
}
