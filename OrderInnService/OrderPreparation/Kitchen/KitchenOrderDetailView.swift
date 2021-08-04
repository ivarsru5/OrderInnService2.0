//
//  KitchenOrderOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import SwiftUI
import FirebaseFirestore

struct KitchenOrderDetailView: View {
    struct EntryCell: View {
        @EnvironmentObject var menuManager: MenuManager
        let entry: RestaurantOrder.OrderEntry

        var body: some View {
            let item = menuManager.menu[entry.itemID]!
            HStack {
                Text(item.name)
                    .bold()
                    .foregroundColor(Color.label)
                Text(" ×\(entry.amount)")
                    .foregroundColor(Color.secondary)

                Spacer()

                Text("\(entry.subtotal(with: item), specifier: "%.2f") EUR")
                    .foregroundColor(Color.label)
            }
        }
    }

    struct OrderPartListing: View {
        let partIndex: Int
        let part: RestaurantOrder.OrderPart

        var headerText: Text {
            if partIndex == 0 {
                return Text("Initial Order")
            } else {
                return Text("Extra Order: \(partIndex)")
            }
        }

        var body: some View {
            Section(header: headerText) {
                ForEach(part.entries.indices) { entryIndex in
                    let entry = part.entries[entryIndex]
                    EntryCell(entry: entry)
                }
            }
        }
    }

    let order: RestaurantOrder
    let zone: Zone
    let table: Table

    var body: some View {
        VStack {
            (Text("Table: ").bold() + Text(table.name))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            List {
                ForEach(order.parts.indices) { partIndex in
                    OrderPartListing(partIndex: partIndex,
                                     part: order.parts[partIndex])
                }
            }
            .listStyle(InsetGroupedListStyle())

            Button(action: {
                // TODO[pn 2021-07-16]
//                        orderOverview.deleteOrder(fromOrder: activeOrder.selectedOrder!)
//                        activeOrder.collectedOrders.removeAll(where: { $0.id == activeOrder.selectedOrder!.id })
//                        presetationMode.wrappedValue.dismiss()
            }, label: {
                Text("Mark Order as Completed")
            })
            .buttonStyle(O6NButtonStyle())
        }
        .navigationBarTitle(Text("Review Order"), displayMode: .inline)
        .onAppear{
            // TODO[pn 2021-07-16]
//            orderOverview.markOrderAsRead(forOrder: activeOrder.selectedOrder!)
        }
    }
}

#if DEBUG
struct KitchenOrderDetailView_Previews: PreviewProvider {
    typealias Order = RestaurantOrder
    typealias Part = RestaurantOrder.OrderPart
    typealias Entry = RestaurantOrder.OrderEntry
    typealias ItemID = MenuItem.FullID

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let zone = Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id)
    static let table = Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: "Z")
    static let order = Order(
        restaurantID: restaurant.id, id: "O", state: .open, table: table.fullID,
        placedBy: "E", createdAt: Date(),
        parts: [
            Part(entries: [
                Entry(itemID: ItemID(category: "C", item: "I1"), amount: 5),
                Entry(itemID: ItemID(category: "C", item: "I2"), amount: 4),
            ]),
            Part(entries: [
                Entry(itemID: ItemID(category: "C", item: "I1"), amount: 3),
                Entry(itemID: ItemID(category: "C", item: "I2"), amount: 2),
            ]),
            Part(entries: [
                Entry(itemID: ItemID(category: "C", item: "I1"), amount: 1),
                Entry(itemID: ItemID(category: "C", item: "I2"), amount: 1),
            ]),
        ]
    )
    static let categories: MenuManager.Categories = [
        "C": MenuCategory(id: "C", name: "Test Category", type: .food, restaurantID: restaurant.id),
    ]
    static let menu: MenuManager.Menu = [
        ItemID(category: "C", item: "I1"): MenuItem(
            id: "I1", name: "Item 1", price: 4.99, isAvailable: true,
            destination: .kitchen, restaurantID: restaurant.id, categoryID: "C"),
        ItemID(category: "C", item: "I2"): MenuItem(
            id: "I2", name: "Item 2", price: 4.99, isAvailable: true,
            destination: .bar, restaurantID: restaurant.id, categoryID: "C"),
    ]
    static let menuManager = MenuManager(debugForRestaurant: restaurant, withMenu: menu, categories: categories)

    static var previews: some View {
        KitchenOrderDetailView(order: order, zone: zone, table: table)
            .environment(\.currentRestaurant, restaurant)
            .environmentObject(menuManager)
    }
}
#endif
