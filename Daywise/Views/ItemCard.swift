import SwiftUI

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statusBadge

            Text(item.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 6)

            Text(CostCalculator.formatDays(item.daysInService))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text(CostCalculator.formatDailyCost(item.dailyCost))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#FF6B6B"))

            Text(item.purchaseDate.formatted(.dateTime.year().month().day()))
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(item.displayStatus)
                .font(.system(size: 11))
                .foregroundStyle(statusColor)
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .serving: return .green
        case .retired: return .orange
        case .sold: return Color(.systemGray)
        }
    }
}
