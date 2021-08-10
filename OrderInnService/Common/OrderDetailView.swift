//
//  OrderDetailView.swift
//  OrderInnService
//
//  Created by paulsnar on 8/10/21.
//

import Combine
import Foundation
import SwiftUI

struct OrderDetailView<Buttons: View>: View {
    @EnvironmentObject var menuManager: MenuManager

    let order: RestaurantOrder
    let buttons: () -> Buttons

    private let zone: Zone
    private let table: Table

    fileprivate init(layout: Layout, order: RestaurantOrder, buttons: @escaping () -> Buttons) {
        self.order = order
        self.buttons = buttons

        let table = layout.tables[order.tableFullID]!
        let zone = layout.zones[table.zoneID]!

        self.zone = zone
        self.table = table
    }
    struct Wrapper: View {
        @Environment(\.currentLayout) @Binding var layout: Layout
        let order: RestaurantOrder
        let buttons: () -> Buttons

        init(order: RestaurantOrder) where Buttons == EmptyView {
            self.order = order
            self.buttons = { EmptyView() }
        }
        init(order: RestaurantOrder,
             @ViewBuilder buttons: @escaping () -> Buttons) {
            self.order = order
            self.buttons = buttons
        }

        var body: OrderDetailView {
            OrderDetailView(layout: layout, order: order, buttons: buttons)
        }
    }

    struct EntryCell: View {
        let item: MenuItem
        let entry: RestaurantOrder.OrderEntry

        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .bodyFont(size: 10)
                    .foregroundColor(entry.isFulfilled ? .green : .label)

                Group {
                    Text(item.name).bold()
                    Text(" ×\(entry.amount)").foregroundColor(.secondary)
                    Spacer()
                    Text("\(entry.subtotal(with: item), specifier: "%.2f") EUR")
                }
                .foregroundColor(entry.isFulfilled ? .secondary : .label)
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Zone: ").bold() + Text(zone.location)
                Spacer()
                Text("Table: ").bold() + Text(table.name)
            }
            .padding([.leading, .trailing])

            List {
                ForEach(order.parts.indices) { index in
                    let part = order.parts[index]
                    let header = index == 0 ? Text("Initial Order") : Text("Extra Order \(index)")
                    Section(header: header) {
                        ForEach(part.entries, id: \.itemID) { entry in
                            let item = menuManager.menu[entry.itemID]!
                            EntryCell(item: item, entry: entry)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            if Buttons.self != EmptyView.self {
                HStack {
                    buttons()
                }
            }
        }
    }
}

#if DEBUG
struct OrderDetailView_Previews: PreviewProvider {
    typealias Order = RestaurantOrder
    typealias Part = Order.OrderPart
    typealias Entry = Order.OrderEntry

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let layout = Layout(autoZones: [
        Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id),
    ], autoTables: [
        Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: "Z"),
    ])
    static let menuManager = MenuManager(debugForRestaurant: restaurant, withAutoMenu: [
        MenuItem(id: "I1", name: "Item 1", price: 4.99, isAvailable: true,
                 destination: .kitchen, restaurantID: restaurant.id, categoryID: "C"),
        MenuItem(id: "I2", name: "Item 2", price: 4.99, isAvailable: true,
                 destination: .kitchen, restaurantID: restaurant.id, categoryID: "C"),
        MenuItem(id: "I3", name: "Item 3", price: 4.99, isAvailable: true,
                 destination: .kitchen, restaurantID: restaurant.id, categoryID: "C"),
    ], autoCategories: [
        MenuCategory(id: "C", name: "Test Category", type: .food, restaurantID: restaurant.id),
    ])
    static var order: Order {
        let entries = Array(menuManager.menu.values)
            .sorted(by: \.id)
            .map { item in
                return Entry(itemID: item.fullID, amount: 1, isFulfilled: false)
            }
        let parts = [
            Part(entries: entries),
            Part(entries: entries.map { $0.with(isFulfilled: true) }),
        ]

        return Order(restaurantID: restaurant.id, id: "O", state: .open,
                     table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                     createdAt: Date(), parts: parts)
    }

    static var previews: some View {
        Group {
            OrderDetailView.Wrapper(order: order, buttons: {
                Button(action: { }, label: { Text("Action 1") })
                Button(action: { }, label: { Text("Action 2") })
            })
            .previewDisplayName("With Buttons")

            OrderDetailView.Wrapper(order: order)
                .previewDisplayName("Without Buttons")
        }
        .buttonStyle(O6NButtonStyle())
        .environment(\.currentLayout, .constant(layout))
        .environmentObject(menuManager)
    }
}
#endif
