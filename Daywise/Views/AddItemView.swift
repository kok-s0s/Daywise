import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    @State private var name = ""
    @State private var priceText = ""
    @State private var purchaseDate = Date()
    @State private var category = "其他"
    @State private var status = ItemStatus.serving
    @State private var soldPriceText = ""
    @State private var soldDate = Date()
    @State private var useCountText = ""
    @State private var satisfactionScore = 3
    @State private var note = ""

    @State private var showNewCategoryAlert = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                categorySection
                statusSection
                usageSection
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
                        .disabled(!canSave)
                }
            }
            .alert("新增分类", isPresented: $showNewCategoryAlert) {
                TextField("分类名称", text: $newCategoryName)
                Button("添加") {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        categoryStore.add(trimmed)
                        category = trimmed
                    }
                    newCategoryName = ""
                }
                Button("取消", role: .cancel) { newCategoryName = "" }
            } message: {
                Text("输入新的分类名称")
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
                ForEach(categoryStore.all, id: \.self) { Text($0).tag($0) }
            }
            Button {
                showNewCategoryAlert = true
            } label: {
                Label("新增分类...", systemImage: "plus.circle")
                    .foregroundStyle(DaywiseTheme.accent)
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

    private var usageSection: some View {
        Section {
            HStack {
                Text("已使用次数")
                TextField("0", text: $useCountText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            Stepper("满意度 \(satisfactionScore)/5", value: $satisfactionScore, in: 1...5)
        } header: {
            Text("使用情况")
        } footer: {
            Text("记录使用次数后，会计算单次使用成本和消费值不值。")
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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let price = CostCalculator.parseAmount(priceText), price > 0, !trimmedName.isEmpty else { return }
        let soldPrice = status == .sold ? CostCalculator.parseAmount(soldPriceText) : nil
        let trimmedUseCount = useCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let initialUseCount = Int(trimmedUseCount)
        let item = Item(
            name: trimmedName,
            price: price,
            purchaseDate: purchaseDate,
            category: category,
            status: status,
            soldPrice: soldPrice,
            soldDate: status == .sold ? soldDate : nil,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        item.useCount = initialUseCount.map { max(0, $0) }
        item.lastUsedAt = (initialUseCount ?? 0) > 0 ? Date() : nil
        item.satisfactionScore = satisfactionScore
        modelContext.insert(item)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private var canSave: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUseCount = useCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let price = CostCalculator.parseAmount(priceText), price > 0 else { return false }
        if !trimmedUseCount.isEmpty, (Int(trimmedUseCount) ?? -1) < 0 { return false }
        if status == .sold {
            guard let soldPrice = CostCalculator.parseAmount(soldPriceText) else { return false }
            return soldPrice >= 0
        }
        return true
    }
}
