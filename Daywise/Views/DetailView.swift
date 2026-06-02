import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: Item

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ZStack {
            DaywiseTheme.pageBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    costCard
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
            Text(CostCalculator.formatDays(item.daysInService))
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("购入价格", String(format: "¥%.2f", item.price))
            Divider().padding(.leading, 16)
            infoRow("购入日期", item.purchaseDate.formatted(.dateTime.year().month().day()))
            Divider().padding(.leading, 16)
            infoRow("分类", item.category)
            if let soldPrice = item.soldPrice {
                Divider().padding(.leading, 16)
                infoRow("出售价格", String(format: "¥%.2f", soldPrice))
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
}
