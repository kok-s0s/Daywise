import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var items: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FFF0F0").ignoresSafeArea()

                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            overviewSection
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

    // MARK: - Sections

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("总览")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                overviewCard("物品总数",
                             value: "\(items.count) 件",
                             icon: "archivebox.fill",
                             color: Color(hex: "#FF6B6B"))
                overviewCard("总投入",
                             value: String(format: "¥%.0f", totalSpend),
                             icon: "creditcard.fill",
                             color: .blue)
                overviewCard("平均日耗",
                             value: String(format: "¥%.2f/天", avgDailyCost),
                             icon: "chart.line.downtrend.xyaxis",
                             color: .orange)
                overviewCard("累计服役",
                             value: "\(totalDaysServed) 天",
                             icon: "calendar.badge.clock",
                             color: .green)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("状态分布")
            VStack(spacing: 0) {
                statusRow("服役中", count: servingItems.count, color: .green)
                Divider().padding(.leading, 16)
                statusRow("已退役", count: retiredItems.count, color: .orange)
                Divider().padding(.leading, 16)
                statusRow("已出售", count: soldItems.count, color: Color(.systemGray))
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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
                Text("\(count) 件  ¥\(Int(spend))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(count), total: Double(maxCount))
                .tint(Color(hex: "#FF6B6B"))
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
                        .foregroundStyle(i == 0 ? Color(hex: "#FF6B6B") : Color(.tertiaryLabel))
                        .frame(width: 28)
                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CostCalculator.formatDailyCost(item.dailyCost))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(colorHigh ? Color(hex: "#FF6B6B") : .green)
                        Text(CostCalculator.formatDays(item.daysInService))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#FF6B6B").opacity(0.35))
            Text("暂无统计数据")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Text("添加物品后即可查看统计")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}
