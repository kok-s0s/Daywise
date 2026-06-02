import SwiftUI
import SwiftData

enum ItemSortOrder: String, CaseIterable {
    case newest     = "最新录入"
    case dailyDesc  = "日耗最高"
    case dailyAsc   = "日耗最低"
    case priceDesc  = "价格最高"
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @State private var showingAddItem = false
    @State private var selectedCategory: String? = nil
    @State private var selectedStatus: ItemStatus? = nil
    @State private var sortOrder: ItemSortOrder = .newest
    @State private var searchText = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var availableCategories: [String] {
        Array(Set(items.map(\.category))).sorted()
    }

    private var servingCount: Int {
        items.filter { $0.status == .serving }.count
    }

    private var totalSpend: Double {
        items.reduce(0) { $0 + $1.price }
    }

    private var avgDailyCost: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0.0) { $0 + $1.dailyCost } / Double(items.count)
    }

    private var hasActiveFilters: Bool {
        selectedStatus != nil || selectedCategory != nil || !searchText.isEmpty
    }

    private var displayItems: [Item] {
        var base = selectedStatus == nil ? Array(items) : items.filter { $0.status == selectedStatus }
        if let cat = selectedCategory {
            base = base.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            base = base.filter {
                $0.name.lowercased().contains(q) ||
                $0.category.lowercased().contains(q) ||
                ($0.note?.lowercased().contains(q) ?? false)
            }
        }
        switch sortOrder {
        case .newest:    return base.sorted { $0.createdAt > $1.createdAt }
        case .dailyDesc: return base.sorted { $0.dailyCost > $1.dailyCost }
        case .dailyAsc:  return base.sorted { $0.dailyCost < $1.dailyCost }
        case .priceDesc: return base.sorted { $0.price > $1.price }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DaywiseTheme.pageBackground.ignoresSafeArea()

                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            commandDeck

                            if displayItems.isEmpty {
                                filterEmptyState
                                    .frame(minHeight: 360)
                            } else {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(displayItems) { item in
                                        NavigationLink(destination: DetailView(item: item)) {
                                            ItemCard(item: item)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            if item.status == .serving {
                                                Button {
                                                    item.status = .retired
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                } label: {
                                                    Label("标为已退役", systemImage: "archivebox")
                                                }
                                            } else if item.status == .retired {
                                                Button {
                                                    item.status = .serving
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                } label: {
                                                    Label("标为服役中", systemImage: "checkmark.circle")
                                                }
                                            }
                                            Button(role: .destructive) {
                                                modelContext.delete(item)
                                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Daywise")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索物品名称、分类、备注")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddItem = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(DaywiseTheme.accent)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }

    // MARK: - Subviews

    private var commandDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAYWISE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(DaywiseTheme.accent)
                    Text(CostCalculator.formatDailyCost(avgDailyCost))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.68)
                        .lineLimit(1)
                    Text("平均日耗")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 10)
                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(displayItems.count)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(DaywiseTheme.accent)
                    Text(hasActiveFilters ? "命中记录" : "全部记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                metricPill(title: "总投入", value: CostCalculator.formatPrice(totalSpend), icon: "creditcard")
                metricPill(title: "服役中", value: "\(servingCount)", icon: "bolt")
                metricPill(title: "总数", value: "\(items.count)", icon: "square.stack.3d.up")
            }

            HStack(spacing: 8) {
                Menu {
                    Button {
                        selectedStatus = nil
                    } label: {
                        Label("全部状态", systemImage: selectedStatus == nil ? "checkmark" : "circle")
                    }
                    ForEach(ItemStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = status
                        } label: {
                            Label(status.displayName, systemImage: selectedStatus == status ? "checkmark" : "circle")
                        }
                    }
                } label: {
                    controlButton(title: selectedStatus?.displayName ?? "状态", icon: "switch.2")
                }

                Menu {
                    Button {
                        selectedCategory = nil
                    } label: {
                        Label("全部分类", systemImage: selectedCategory == nil ? "checkmark" : "circle")
                    }
                    ForEach(availableCategories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Label(category, systemImage: selectedCategory == category ? "checkmark" : "circle")
                        }
                    }
                } label: {
                    controlButton(title: selectedCategory ?? "分类", icon: "tag")
                }

                Menu {
                    ForEach(ItemSortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "circle")
                        }
                    }
                } label: {
                    controlButton(title: sortOrder.rawValue, icon: "arrow.up.arrow.down")
                }

                if hasActiveFilters {
                    Button {
                        selectedStatus = nil
                        selectedCategory = nil
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 34, height: 34)
                            .background(DaywiseTheme.softSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
                            .overlay {
                                RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                                    .stroke(DaywiseTheme.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [DaywiseTheme.elevatedSurface, DaywiseTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
        .shadow(color: DaywiseTheme.glow, radius: 18, x: 0, y: 0)
        .shadow(color: DaywiseTheme.shadow, radius: 16, x: 0, y: 12)
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DaywiseTheme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(DaywiseTheme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
    }

    private func controlButton(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DaywiseTheme.accent)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .padding(.horizontal, 8)
        .background(DaywiseTheme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DaywiseTheme.cardRadius)
                .stroke(DaywiseTheme.border, lineWidth: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("还没有物品")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Text("点击右上角 + 开始记录第一件物品")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
            Text("无匹配结果")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Text("换个筛选条件试试")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
