import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var items: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                DaywiseTheme.pageBackground.ignoresSafeArea()

                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            overviewSection
                            reviewSection
                            statusSection
                            categorySection
                            rankingSection
                        }
                        .padding(16)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Computed

    private var totalSpend: Double       { items.reduce(0) { $0 + $1.price } }
    private var servingItems: [Item]     { items.filter { $0.status == .serving } }
    private var retiredItems: [Item]     { items.filter { $0.status == .retired } }
    private var soldItems: [Item]        { items.filter { $0.status == .sold } }
    private var avgDailyCost: Double {
        items.isEmpty ? 0 : items.reduce(0) { $0 + $1.dailyCost } / Double(items.count)
    }
    private var totalDaysServed: Int {
        items.reduce(0) { $0 + $1.daysInService }
    }
    private var idleItems: [Item] {
        items.filter {
            $0.status == .serving &&
            $0.isUsageTracked &&
            (($0.daysSinceLastUse ?? $0.daysInService) >= 30)
        }
    }
    private var impulseItems: [Item] {
        items.filter { $0.valueVerdict == .impulse }
    }
    private var bestUseItem: Item? {
        items.compactMap { item -> (Item, Double)? in
            guard let cost = item.costPerUse else { return nil }
            return (item, cost)
        }
        .sorted { $0.1 < $1.1 }
        .first?.0
    }
    private var worstUseItem: Item? {
        items.compactMap { item -> (Item, Double)? in
            guard let cost = item.costPerUse else { return nil }
            return (item, cost)
        }
        .sorted { $0.1 > $1.1 }
        .first?.0
    }

    // MARK: - Sections

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("总览")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                overviewCard("物品总数",
                             value: "\(items.count) 件",
                             icon: "archivebox.fill",
                             color: .primary)
                overviewCard("总投入",
                             value: CostCalculator.formatPrice(totalSpend),
                             icon: "creditcard.fill",
                             color: .primary)
                overviewCard("平均日耗",
                             value: String(format: "¥%.2f/天", avgDailyCost),
                             icon: "chart.line.downtrend.xyaxis",
                             color: .primary)
                overviewCard("累计服役",
                             value: "\(totalDaysServed) 天",
                             icon: "calendar.badge.clock",
                             color: .primary)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("状态分布")
            VStack(spacing: 0) {
                statusRow("服役中", count: servingItems.count, color: .primary)
                Divider().padding(.leading, 16)
                statusRow("已退役", count: retiredItems.count, color: .secondary)
                Divider().padding(.leading, 16)
                statusRow("已出售", count: soldItems.count, color: Color(.systemGray))
            }
            .background(DaywiseTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                    .stroke(DaywiseTheme.border, lineWidth: 1)
            }
            .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("消费复盘")
                Spacer()
                ShareLink(item: reviewShareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .foregroundStyle(DaywiseTheme.accent)
                }
            }
            VStack(spacing: 0) {
                reviewRow("最超值", value: bestUseItem?.name ?? "暂无", detail: bestUseItem.map { CostCalculator.formatCostPerUse($0.costPerUse) } ?? "记录使用后生成")
                Divider().padding(.leading, 16)
                reviewRow("最该复盘", value: worstUseItem?.name ?? "暂无", detail: worstUseItem.map { CostCalculator.formatCostPerUse($0.costPerUse) } ?? "记录使用后生成")
                Divider().padding(.leading, 16)
                reviewRow("可能闲置", value: "\(idleItems.count) 件", detail: "已追踪且 30 天未使用")
                Divider().padding(.leading, 16)
                reviewRow("冲动消费", value: "\(impulseItems.count) 件", detail: "使用太少且成本偏高")
            }
            .background(DaywiseTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                    .stroke(DaywiseTheme.border, lineWidth: 1)
            }
            .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
        }
    }

    private var categorySection: some View {
        let groups = Dictionary(grouping: items, by: \.category)
            .map { (name: $0.key, count: $0.value.count, spend: $0.value.reduce(0) { $0 + $1.price }) }
            .sorted { $0.count > $1.count }
        let maxCount = groups.map(\.count).max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("分类分布")
            VStack(spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.element.name) { i, g in
                    if i > 0 { Divider().padding(.leading, 16) }
                    categoryRow(g.name, count: g.count, spend: g.spend, maxCount: maxCount)
                }
            }
            .background(DaywiseTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                    .stroke(DaywiseTheme.border, lineWidth: 1)
            }
            .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
        }
    }

    private var rankingSection: some View {
        let serving = servingItems
        let topCost  = Array(serving.sorted { $0.dailyCost > $1.dailyCost }.prefix(3))
        let bestVal  = Array(serving.filter { $0.daysInService >= 30 }
                                    .sorted { $0.dailyCost < $1.dailyCost }.prefix(3))

        return VStack(alignment: .leading, spacing: 24) {
            if !topCost.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("日耗最高 Top 3")
                    rankCard(topCost, colorHigh: true)
                }
            }
            if !bestVal.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("最超值 Top 3")
                    rankCard(bestVal, colorHigh: false)
                }
            }
        }
    }

    // MARK: - Components

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }

    private func overviewCard(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private func statusRow(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(count) 件")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            ProgressView(value: items.isEmpty ? 0 : Double(count) / Double(items.count))
                .frame(width: 72)
                .tint(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func categoryRow(_ name: String, count: Int, spend: Double, maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(count) 件  \(CostCalculator.formatPrice(spend))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(count), total: Double(maxCount))
                .tint(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func reviewRow(_ label: String, value: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func rankCard(_ rankItems: [Item], colorHigh: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rankItems.enumerated()), id: \.element.id) { i, item in
                if i > 0 { Divider().padding(.leading, 16) }
                HStack(spacing: 12) {
                    Text("#\(i + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(i == 0 ? Color.primary : Color(.tertiaryLabel))
                        .frame(width: 28)
                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CostCalculator.formatDailyCost(item.dailyCost))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(colorHigh ? Color.primary : .secondary)
                        Text(CostCalculator.formatDays(item.daysInService))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(DaywiseTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.shadow, radius: 3, x: 0, y: 1)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("暂无统计数据")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Text("添加物品后即可查看统计")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    private var reviewShareText: String {
        """
        Daywise 消费复盘
        总投入：\(CostCalculator.formatPrice(totalSpend))
        平均日耗：\(CostCalculator.formatDailyCost(avgDailyCost))
        最超值：\(bestUseItem?.name ?? "暂无")
        最该复盘：\(worstUseItem?.name ?? "暂无")
        可能闲置：\(idleItems.count) 件
        冲动消费：\(impulseItems.count) 件
        """
    }
}
