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
    @State private var sortOrder: ItemSortOrder = .newest

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var availableCategories: [String] {
        Array(Set(items.map(\.category))).sorted()
    }

    private var displayItems: [Item] {
        let base = selectedCategory == nil
            ? Array(items)
            : items.filter { $0.category == selectedCategory }
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
                Color(hex: "#FFF0F0").ignoresSafeArea()

                VStack(spacing: 0) {
                    summaryBar
                    Divider()

                    if !items.isEmpty {
                        categoryFilterBar
                        Divider()
                    }

                    if items.isEmpty {
                        emptyState
                    } else if displayItems.isEmpty {
                        categoryEmptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(displayItems) { item in
                                    NavigationLink(destination: DetailView(item: item)) {
                                        ItemCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Daywise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddItem = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(ItemSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                if sortOrder == order {
                                    Label(order.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(order.rawValue)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }

    // MARK: - Subviews

    private var summaryBar: some View {
        HStack(spacing: 0) {
            summaryCell("\(items.count)", label: "物品总数")
            Divider().frame(height: 36)
            summaryCell(String(format: "¥%.0f", items.reduce(0) { $0 + $1.price }), label: "总投入")
            Divider().frame(height: 36)
            summaryCell({
                let avg = items.isEmpty ? 0.0 : items.reduce(0.0) { $0 + $1.dailyCost } / Double(items.count)
                return String(format: "¥%.2f", avg)
            }(), label: "平均日耗")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white)
    }

    private func summaryCell(_ value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "#FF6B6B"))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "全部", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(availableCategories, id: \.self) { cat in
                    FilterChip(title: cat, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.white)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#FF6B6B").opacity(0.35))
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

    private var categoryEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(Color(hex: "#FF6B6B").opacity(0.35))
            Text("该分类暂无物品")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "#FF6B6B") : Color(.systemGray6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
