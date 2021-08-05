//
//  OrderListCell.swift
//  OrderInnService
//
//  Created by paulsnar on 8/5/21.
//

import SwiftUI

struct OrderListCell: View {
    let order: RestaurantOrder
    let zone: Zone
    let table: Table

    init(order: RestaurantOrder, zone: Zone, table: Table) {
        self.order = order
        self.zone = zone
        self.table = table
    }

    typealias IconConfiguration = (name: String, size: CGFloat, weight: Font.Weight, color: Color)
    var iconConfiguration: IconConfiguration {
        switch order.state {
        case .new: return ("circle.fill", 10, .medium, .blue)
        case .open: return ("circle.fill", 10, .medium, .label)
        case .fulfilled: return ("checkmark", 14, .bold, .secondary)
        case .cancelled: return ("xmark", 14, .bold, .secondary)
        }
    }
    // NOTE[pn]: This should be the maximum of iconConfiguration `size` options.
    // This helps align icons of different statuses to be more tabular.
    private static let maxStatusIconWidth = CGFloat(14)
    @ViewBuilder var statusIcon: some View {
        let config = iconConfiguration
        Image(systemName: config.name)
            .bodyFont(size: config.size, weight: config.weight)
            .foregroundColor(config.color)
            .frame(width: OrderListCell.maxStatusIconWidth, alignment: .center)
    }

    var body: some View {
        HStack {
            statusIcon

            Group {
                Text("Zone: ").bold() + Text(zone.location)
                Spacer()
                Text("Table: ").bold() + Text(table.name)
            }
            .foregroundColor(order.state.isOpen ? .label : .secondary)
        }
    }
}

#if DEBUG
struct OrderListCell_Previews: PreviewProvider {
    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let zone = Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id)
    static let table = Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: zone.id)
    static let orders = [
        RestaurantOrder(restaurantID: restaurant.id, id: "O1", state: .new,
                        table: table.fullID, placedBy: "E", createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: restaurant.id, id: "O2", state: .open,
                        table: table.fullID, placedBy: "E", createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: restaurant.id, id: "O3", state: .fulfilled,
                        table: table.fullID, placedBy: "E", createdAt: Date(), parts: []),
        RestaurantOrder(restaurantID: restaurant.id, id: "O4", state: .cancelled,
                        table: table.fullID, placedBy: "E", createdAt: Date(), parts: []),
    ]

    static var previews: some View {
        List {
            ForEach(orders) { order in
                OrderListCell(order: order, zone: zone, table: table)
            }
        }
    }
}
#endif
