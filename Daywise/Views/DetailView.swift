import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: Item

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingUseCountEditor = false
    @State private var useCountInput = ""

    var body: some View {
        ZStack {
            DaywiseTheme.pageBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    costCard
                    usageCard
                    infoCard
                    if let note = item.note, !note.isEmpty {
                        noteCard(note: note)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(item: shareText) {
                        Label("分享消费卡片", systemImage: "square.and.arrow.up")
                    }
                    Button("编辑") { showingEdit = true }
                    Button("删除", role: .destructive) { showingDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditItemView(item: item)
        }
        .alert("设置使用次数", isPresented: $showingUseCountEditor) {
            TextField("使用次数", text: $useCountInput)
                .keyboardType(.numberPad)
            Button("保存") {
                applyUseCountInput()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("直接输入累计使用次数。")
        }
        .alert("删除物品", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                modelContext.delete(item)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确认删除「\(item.name)」？此操作无法撤销。")
        }
    }

    private var costCard: some View {
        VStack(spacing: 10) {
            HStack {
                statusBadge
                Spacer()
            }
            Text(CostCalculator.formatDailyCost(item.dailyCost))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.primary)
            Text("\(CostCalculator.formatDays(item.daysInService)) · \(item.valueVerdict.rawValue)")
                .font(.subheadline)
                .foregroundStyle(DaywiseTheme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("单次使用成本")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CostCalculator.formatCostPerUse(item.costPerUse))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(DaywiseTheme.accent)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        item.unmarkUsed()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .black))
                            .frame(width: 34, height: 34)
                            .background(DaywiseTheme.softSurface)
                            .foregroundStyle(item.effectiveUseCount > 0 ? .primary : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
                            .overlay {
                                RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                                    .stroke(DaywiseTheme.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(item.effectiveUseCount == 0)

                    Button {
                        item.markUsed()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Label("今天用了", systemImage: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(DaywiseTheme.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Button {
                    useCountInput = item.useCount.map(String.init) ?? ""
                    showingUseCountEditor = true
                } label: {
                    usageMetric("次数", useCountText, "number")
                }
                .buttonStyle(.plain)
                usageMetric("最近", lastUsedText, "clock")
                usageMetric("满意", "\(item.satisfactionScore ?? 3)/5", "star")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.valueVerdict.rawValue)
                    .font(.headline)
                Text(item.valueVerdict.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("购入价格", CostCalculator.formatPrice(item.price, decimals: 2))
            Divider().padding(.leading, 16)
            infoRow("购入日期", item.purchaseDate.formatted(.dateTime.year().month().day()))
            Divider().padding(.leading, 16)
            infoRow("分类", item.category)
            if let soldPrice = item.soldPrice {
                Divider().padding(.leading, 16)
                infoRow("出售价格", CostCalculator.formatPrice(soldPrice, decimals: 2))
                Divider().padding(.leading, 16)
                infoRow("净成本", CostCalculator.formatPrice(item.netCost, decimals: 2))
            }
            if let soldDate = item.soldDate {
                Divider().padding(.leading, 16)
                infoRow("出售日期", soldDate.formatted(.dateTime.year().month().day()))
            }
            Divider().padding(.leading, 16)
            infoRow("录入时间", item.createdAt.formatted(.dateTime.year().month().day()))
        }
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private func noteCard(note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Text(note)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(item.displayStatus)
                .font(.subheadline)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
    }

    private var statusColor: Color {
        switch item.status {
        case .serving: return .primary
        case .retired: return .secondary
        case .sold: return Color(.systemGray)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func usageMetric(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(DaywiseTheme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(DaywiseTheme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
    }

    private var lastUsedText: String {
        guard let days = item.daysSinceLastUse else { return "未记录" }
        if days == 0 { return "今天" }
        return "\(days) 天前"
    }

    private var shareText: String {
        """
        Daywise 消费卡片
        \(item.name)
        \(item.valueVerdict.rawValue)：\(item.valueVerdict.message)
        日耗：\(CostCalculator.formatDailyCost(item.dailyCost))
        单次：\(CostCalculator.formatCostPerUse(item.costPerUse))
        使用：\(useCountText)
        """
    }

    private var useCountText: String {
        item.isUsageTracked ? "\(item.effectiveUseCount)" : "未追踪"
    }

    private func applyUseCountInput() {
        let trimmed = useCountInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let count = Int(trimmed) else { return }
        item.setUseCount(count)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
