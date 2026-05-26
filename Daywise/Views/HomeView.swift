import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @State private var showingAddItem = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FFF0F0").ignoresSafeArea()

                VStack(spacing: 0) {
                    summaryBar
                    Divider()

                    if items.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(items) { item in
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
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 0) {
            summaryCell(
                value: "\(items.count)",
                label: "物品总数"
            )
            Divider().frame(height: 36)
            summaryCell(
                value: String(format: "¥%.0f", items.reduce(0) { $0 + $1.price }),
                label: "总投入"
            )
            Divider().frame(height: 36)
            summaryCell(
                value: {
                    let avg = items.isEmpty ? 0.0 : items.reduce(0.0) { $0 + $1.dailyCost } / Double(items.count)
                    return String(format: "¥%.2f", avg)
                }(),
                label: "平均日耗"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white)
    }

    private func summaryCell(value: String, label: String) -> some View {
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
}
