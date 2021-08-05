//
//  KitchenOrderOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import Combine
import SwiftUI

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

    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.presentationMode) @Binding var presentationMode: PresentationMode
    let order: RestaurantOrder
    let zone: Zone
    let table: Table
    @State var markOrderCompleteCancellable: AnyCancellable?

    var body: some View {
        VStack {
            HStack {
                Text("Zone: ").bold() + Text(zone.location)
                Spacer()
                Text("Table: ").bold() + Text(table.name)
            }
            .padding()

            List {
                ForEach(order.parts.indices) { partIndex in
                    OrderPartListing(partIndex: partIndex,
                                     part: order.parts[partIndex])
                }
            }
            .listStyle(InsetGroupedListStyle())

            Button(action: {
                // TODO[pn 2021-08-05]: This isn't fully correct, given that
                // closing orders is done by the manager, not the kitchen. This
                // should instead ask which part to mark as fulfilled and do
                // that instead. As is, this is intended for demonstration
                // purposes only.
                markOrderCompleteCancellable = orderManager.update(order: order, setState: .fulfilled)
                    .mapError { error in
                        // TODO[pn 2021-08-05]
                        fatalError("FIXME Failed to mark order as completed: \(String(describing: error))")
                    }
                    .sink { _ in
                        if let _ = markOrderCompleteCancellable {
                            markOrderCompleteCancellable = nil
                        }
                        if presentationMode.isPresented {
                            presentationMode.dismiss()
                        }
                    }

            }, label: {
                Text("Mark Order as Completed")
            })
            .buttonStyle(O6NButtonStyle(isLoading: markOrderCompleteCancellable != nil))
        }
        .navigationBarTitle(Text("Review Order"), displayMode: .inline)
        .onAppear {
            if order.state == .new {
                var sub: AnyCancellable?
                sub = orderManager.update(order: order, setState: .open)
                    .catch { _ -> Empty<RestaurantOrder, Never> in
                        return Empty()
                    }
                    .ignoreOutput()
                    .sink(receiveCompletion: { _ in
                        if let _ = sub {
                            sub = nil
                        }
                    })
            }
        }
    }
}

#if DEBUG
struct KitchenOrderDetailView_Previews: PreviewProvider {
    typealias Order = RestaurantOrder
    typealias Part = RestaurantOrder.OrderPart
    typealias Entry = RestaurantOrder.OrderEntry
    typealias ItemID = MenuItem.FullID

    class OrderManagerMock: OrderManager {
        override func update(order: Order, setState newState: Order.OrderState) -> AnyPublisher<Order, Error> {
            guard let index = orders.firstIndex(where: { $0.id == order.id }) else {
                return Empty(outputType: Order.self, failureType: Error.self).eraseToAnyPublisher()
            }

            let updatedOrder = Order(restaurantID: order.restaurantID, id: order.id,
                                     state: newState, table: order.tableFullID,
                                     placedBy: order.placedBy.documentID,
                                     createdAt: order.createdAt, parts: order.parts)
            return Just(updatedOrder)
                .delay(for: .seconds(3), scheduler: RunLoop.main)
                .map { [self] order in
                    self.orders[index] = updatedOrder
                    return order
                }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

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
    static let orderManager = OrderManagerMock(debugForRestaurant: restaurant, withOrders: [order])

    struct Wrapper: View {
        @ObservedObject var orderManager: OrderManager
        let restaurant: Restaurant
        let zone: Zone
        let table: Table
        let menuManager: MenuManager

        var body: some View {
            KitchenOrderDetailView(order: orderManager.orders.first!,
                                   zone: zone, table: table)
                .environment(\.currentRestaurant, restaurant)
                .environmentObject(menuManager)
                .environmentObject(orderManager)
        }
    }

    static var previews: some View {
        Wrapper(orderManager: orderManager as OrderManager,
                restaurant: restaurant, zone: zone, table: table,
                menuManager: menuManager)
    }
}
#endif
