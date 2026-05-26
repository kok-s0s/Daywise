import SwiftUI
import SwiftData
import PhotosUI

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

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isRecognizing = false
    @State private var toast: String?
    @State private var highlightedFields: Set<String> = []

    private let ocrService = OCRService()
    private let categories = ["数码", "家电", "服饰", "家居", "运动", "美妆", "书籍", "其他"]

    var body: some View {
        NavigationStack {
            Form {
                ocrSection
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
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: toast)
        }
    }

    private var ocrSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("从截图识别导入")
                    Spacer()
                    if isRecognizing {
                        ProgressView().scaleEffect(0.8)
                    }
                }
                .foregroundStyle(Color(hex: "#FF6B6B"))
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task { await recognizePhoto(newItem) }
            }
        } header: {
            Text("截图识别")
        } footer: {
            Text("选择电商截图，自动填充商品名和价格")
        }
    }

    private var basicSection: some View {
        Section("基本信息") {
            HStack {
                Text("名称")
                TextField("物品名称", text: $name)
                    .multilineTextAlignment(.trailing)
                    .background(highlightedFields.contains("name") ? Color.yellow.opacity(0.25) : .clear)
            }
            HStack {
                Text("价格")
                HStack(spacing: 2) {
                    Text("¥").foregroundStyle(.secondary)
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .background(highlightedFields.contains("price") ? Color.yellow.opacity(0.25) : .clear)
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

    private func recognizePhoto(_ item: PhotosPickerItem) async {
        isRecognizing = true
        defer { isRecognizing = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            showToast("图片加载失败，请重试")
            return
        }

        let result = await ocrService.recognize(image: image)

        withAnimation {
            highlightedFields = []
            if let detected = result.name, !detected.isEmpty {
                name = detected
                highlightedFields.insert("name")
            }
            if let detectedPrice = result.price {
                priceText = String(format: "%.2f", detectedPrice)
                highlightedFields.insert("price")
            }
        }

        if result.name != nil || result.price != nil {
            showToast("识别成功，请确认并修改")
        } else {
            showToast("未能识别，请手动输入")
        }

        try? await Task.sleep(for: .seconds(3))
        withAnimation { highlightedFields = [] }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { toast = nil }
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
