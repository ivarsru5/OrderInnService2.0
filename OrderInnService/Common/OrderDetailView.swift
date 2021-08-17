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
    @ObservedObject var extraPart: MenuView.PendingOrderPart
    let buttons: () -> Buttons

    private let zone: Zone
    private let table: Table

    fileprivate init(layout: Layout, menuManager: MenuManager,
                     order: RestaurantOrder, extraPart: MenuView.PendingOrderPart,
                     buttons: @escaping () -> Buttons) {
        self.order = order
        self.buttons = buttons
        self._extraPart = ObservedObject(wrappedValue: extraPart)

        let table = layout.tables[order.tableFullID]!
        let zone = layout.zones[table.zoneID]!

        self.zone = zone
        self.table = table
    }
    struct Wrapper: View {
        @Environment(\.currentLayout) @Binding var layout: Layout
        @EnvironmentObject var menuManager: MenuManager

        let order: RestaurantOrder
        let extraPart: MenuView.PendingOrderPart?
        let buttons: () -> Buttons

        init(order: RestaurantOrder,
             extraPart: MenuView.PendingOrderPart? = nil) where Buttons == EmptyView {
            self.init(order: order, extraPart: extraPart,
                      buttons: { EmptyView() })
        }
        init(order: RestaurantOrder,
             extraPart: MenuView.PendingOrderPart? = nil,
             @ViewBuilder buttons: @escaping () -> Buttons) {
            self.order = order
            self.extraPart = extraPart
            self.buttons = buttons
        }

        var part: MenuView.PendingOrderPart {
            extraPart ?? MenuView.PendingOrderPart(menuManager: menuManager)
        }

        var body: some View {
            OrderDetailView(layout: layout, menuManager: menuManager,
                            order: order, extraPart: part,
                            buttons: buttons)
        }
    }

    struct EntryCell: View {
        let item: MenuItem
        let entry: RestaurantOrder.Entry
        let remove: (() -> ())?

        init(item: MenuItem, entry: RestaurantOrder.Entry,
             remove: (() -> ())? = nil) {
            precondition(item.fullID == entry.itemID)
            self.item = item
            self.entry = entry
            self.remove = remove
        }

        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .bodyFont(size: 10)
                    .foregroundColor(remove != nil ? .secondary :
                                        entry.isFulfilled ? .green : .label)

                Group {
                    Text(item.name).bold()
                    Text(" ×\(entry.amount)").foregroundColor(.secondary)
                    Spacer()
                    Text("EUR \(entry.subtotal(with: item), specifier: "%.2f")")
                }
                .foregroundColor(entry.isFulfilled ? .secondary : .label)

                IfLet(remove) { remove in
                    Button(action: remove, label: {
                        Image(systemName: "xmark.circle")
                    })
                    .buttonStyle(DefaultButtonStyle())
                }
            }
        }
    }

    var body: some View {
        VStack {
            #if DEBUG
            Text("ID: \(order.id)").foregroundColor(.secondary)
            #endif

            HStack {
                Text("Zone: ").bold() + Text(zone.location)
                Spacer()
                Text("Table: ").bold() + Text(table.name)
            }
            .padding([.leading, .trailing])

            List {
                if !extraPart.entries.isEmpty {
                    Section(header: Text("Selected Items")) {
                        // HACK[pn]: Though it may seem more idiomatic to
                        // iterate over the indices instead of the entries
                        // themselves, apparently that's dangerous because any
                        // shift in the index range can cause the subscript
                        // operation to fail because SwiftUI tries to render
                        // from stale data? Which leads to an assertion failure
                        // and a crash.
                        // Therefore we iterate over the entries themselves
                        // under the invariant that each item ID appears in only
                        // one entry in this section.
                        // (Followup [pn]: Appears that, indeed, passing a
                        // range to ForEach implies that the range is constant
                        // and so SwiftUI won't check if the range ever changes.
                        // Which is exactly what we don't want. So we iterate
                        // over a dynamic entry list instead. Thanks, SwiftUI!)
                        ForEach(extraPart.entries, id: \.itemID) { entry in
                            let item = menuManager.menu[entry.itemID]!
                            EntryCell(item: item, entry: entry, remove: {
                                withAnimation {
                                    extraPart.setAmount(0, forItemWithID: entry.itemID)
                                }
                            })
                        }
                    }
                }

                let partIndices = Array(order.parts.indices)
                ForEach(partIndices, id: \.self) { index in
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

            HStack {
                Text("Total Order Amount:").foregroundColor(.secondary)
                Spacer()
                if extraPart.entries.isEmpty {
                    let total = order.total(using: menuManager.menu)
                    Text("EUR \(total, specifier: "%.2f")").bold()
                } else if order.parts.isEmpty {
                    Text("EUR \(extraPart.subtotal, specifier: "%.2f")").bold()
                } else {
                    let oldTotal = order.total(using: menuManager.menu)
                    let newTotal = oldTotal + extraPart.subtotal

                    Group {
                        Text("EUR \(oldTotal, specifier: "%.2f")")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.secondaryLabel)
                    Text("EUR \(newTotal, specifier: "%.2f")").bold()
                }
            }
            .padding()

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
    typealias Part = Order.Part
    typealias Entry = Order.Entry

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
    static let entries = Array(menuManager.menu.values)
        .sorted(by: \.id)
        .map { item in
            return Entry(itemID: item.fullID, amount: 1, isFulfilled: false)
        }
    static var order: Order {
        let parts = [
            Part(index: 0, entries: entries),
            Part(index: 1, entries: entries.map { $0.with(isFulfilled: true) }),
        ]

        return Order(restaurantID: restaurant.id, id: "O", state: .open,
                     table: Table.FullID(zone: "Z", table: "T"), placedBy: "E",
                     createdAt: Date(), parts: parts)
    }
    static var extraPart: MenuView.PendingOrderPart {
        let part = MenuView.PendingOrderPart(menuManager: menuManager)
        part.entries.append(contentsOf: entries)
        return part
    }

    static var previews: some View {
        Group {
            OrderDetailView.Wrapper(order: order, extraPart: extraPart, buttons: {
                Button(action: { }, label: { Text("Action 1") })
                Button(action: { }, label: { Text("Action 2") })
            })
            .previewDisplayName("With Buttons")

            OrderDetailView.Wrapper(order: order, extraPart: extraPart)
                .previewDisplayName("Without Buttons")
        }
        .buttonStyle(O6NButtonStyle())
        .environment(\.currentLayout, .constant(layout))
        .environmentObject(menuManager)
    }
}
#endif
