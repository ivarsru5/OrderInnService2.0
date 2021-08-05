//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import SwiftUI

struct ActiveOrderDetailView: View {
    struct EntryCell: View {
        let entry: RestaurantOrder.OrderEntry
        let item: MenuItem
        let remove: (() -> ())?

        init(entry: RestaurantOrder.OrderEntry, item: MenuItem,
             remove: (() -> ())? = nil) {
            self.entry = entry
            self.item = item
            self.remove = remove
        }

        var body: some View {
            HStack {
                Text(verbatim: item.name)
                    .bold()
                    .foregroundColor(.label)
                Text(" ×\(entry.amount)")
                    .foregroundColor(.secondary)

                Spacer()

                Text("EUR \(entry.subtotal(with: item), specifier: "%.2f")")
                    .foregroundColor(.label)

                if remove != nil {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            remove!()
                        }
                    }, label: {
                        Image(systemName: "xmark.circle")
//                            .symbolSize(20)
//                            .foregroundColor(.blue)
                    })
                }
            }
        }
    }

    let order: RestaurantOrder
    @Environment(\.currentLayout) @Binding var layout: Layout
    @EnvironmentObject var menuManager: MenuManager
    @State var nextExtraPartActive = false
    @StateObject var nextExtraPart: MenuView.PendingOrderPart
    @State var showPickerOverlay = false
    let zone: Zone
    let table: Table

    private init(order: RestaurantOrder, menuManager: MenuManager, layout: Layout) {
        self.order = order
        let table = layout.tables[order.tableFullID]!
        self.table = table
        self.zone = layout.zones[table.zoneID]!
        self._nextExtraPart = StateObject(wrappedValue: MenuView.PendingOrderPart(menuManager: menuManager))
    }

    struct Wrapper: View {
        @Environment(\.currentLayout) @Binding var layout: Layout
        @EnvironmentObject var menuManager: MenuManager
        let order: RestaurantOrder

        var body: some View {
            ActiveOrderDetailView(order: order, menuManager: menuManager, layout: layout)
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Zone: ").bold() + Text(verbatim: zone.location)
                Spacer()
                Text("Table: ").bold() + Text(verbatim: table.name)
            }
            .padding([.leading, .trailing])

            List {
                if !nextExtraPart.isEmpty {
                    Section(header: Text("Selected Items")) {
                        ForEach(nextExtraPart.entries, id: \.itemID) { entry in
                            EntryCell(entry: entry, item: menuManager.menu[entry.itemID]!, remove: {
                                nextExtraPart.setAmount(0, forItemWithID: entry.itemID)
                            })
                        }
                    }
                }

                ForEach(order.parts.indices, id: \.self) { index in
                    let part = order.parts[index]
                    let header = Text(index == 0 ? "Initial Order" : "Extra Order: \(index)")

                    Section(header: header) {
                        ForEach(part.entries, id: \.itemID) { entry in
                            EntryCell(entry: entry, item: menuManager.menu[entry.itemID]!)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            HStack {
                Text("Total Order Amount:")
                    .foregroundColor(.secondary)

                Spacer()

                Text("EUR \(order.total(using: menuManager.menu), specifier: "%.2f")")
                    .bold()
                    .foregroundColor(.label)
            }
            .padding()

            HStack {
                if nextExtraPartActive {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)) {
//                            orderOverview.submitExtraOrder(from: activeOrder.selectedOrder!)
                            // TODO
                        }
                    }, label: {
                        Text("Submit Extra Order")
                    })
                }

                Button(action: {
                    withAnimation {
                        nextExtraPartActive = true
                    }
                    showPickerOverlay = true
                }, label: {
                    Text("Add Items to Order")
                })
            }
            .buttonStyle(O6NButtonStyle())
        }
        .navigationTitle("Review Order")
        .popover(isPresented: $showPickerOverlay) {
            NavigationView {
                MenuView(menuManager: menuManager,
                         context: .appendedOrder(part: nextExtraPart))
            }
        }
    }
}

#if DEBUG
struct ActiveOrderOverview_Previews: PreviewProvider {
    typealias Part = RestaurantOrder.OrderPart
    typealias Entry = RestaurantOrder.OrderEntry
    typealias ID = MenuItem.FullID

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let menuManager = MenuManager(debugForRestaurant: restaurant, withMenu: [
        ID(string: "C/I1")!: MenuItem(
            id: "I1", name: "Item 1", price: 4.99, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "C"),
        ID(string: "C/I2")!: MenuItem(
            id: "I2", name: "Item 2", price: 9.99, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "C"),
        ID(string: "C/I3")!: MenuItem(
            id: "I3", name: "Item 3", price: 19.99, isAvailable: true,
            destination: .kitchen, restaurantID: "R", categoryID: "C"),
    ], categories: [
        "C": MenuCategory(id: "C", name: "Test Category", type: .food, restaurantID: restaurant.id),
    ])
    static let part = Part(entries: [
        Entry(itemID: ID(string: "C/I1")!, amount: 2),
        Entry(itemID: ID(string: "C/I2")!, amount: 3),
        Entry(itemID: ID(string: "C/I3")!, amount: 1),
    ])
    static let layout = Layout(zones: [
        "Z": Zone(id: "Z", location: "Test Zone", restaurantID: "R"),
    ], tables: [
        Table.FullID(zone: "Z", table: "T"):
            Table(id: "T", name: "Test Table", restaurantID: "R", zoneID: "Z"),
    ])
    static let order = RestaurantOrder(restaurantID: "R", id: "O", state: .open,
                                       table: Table.FullID(zone: "Z", table: "T"),
                                       placedBy: "U", createdAt: Date(), parts: [part])

    static var previews: some View {
        NavigationView {
            ActiveOrderDetailView.Wrapper(order: order)
                .environment(\.currentLayout, .constant(layout))
                .environmentObject(menuManager)
        }
    }
}
#endif
