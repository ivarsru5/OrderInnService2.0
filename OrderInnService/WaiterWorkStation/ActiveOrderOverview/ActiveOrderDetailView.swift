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

                Text("EUR \(entry.subtotal, specifier: "%.2f")")
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
    let zone: Zone
    let table: Table
    @State var extraPart: MenuView.PendingOrderPart? = nil
    @State var showPickerOverlay = false

    var body: some View {
        VStack {
            HStack {
                Text("Zone: ").bold() + Text(verbatim: zone.location)
                Spacer()
                Text("Table: ").bold() + Text(verbatim: table.name)
            }
            .padding([.leading, .trailing])

            List {
                if extraPart != nil {
                    Section(header: Text("Selected Items")) {
                        ForEach(extraPart!.entries, id: \.itemID) { entry in
                            EntryCell(entry: entry, item: entry.item, remove: {
                                // TODO
                            })
                        }
                    }
                }

                ForEach(order.parts.indices, id: \.self) { index in
                    let part = order.parts[index]
                    let header = Text(index == 0 ? "Initial Order" : "Extra Order: \(index)")

                    Section(header: header) {
                        ForEach(part.entries, id: \.itemID) { entry in
                            EntryCell(entry: entry, item: entry.item)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            HStack {
                Text("Total Order Amount:")
                    .foregroundColor(.secondary)

                Spacer()

                Text("EUR \(order.total, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(.label)
            }
            .padding()

            HStack {
                if extraPart != nil {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)){
//                            orderOverview.submitExtraOrder(from: activeOrder.selectedOrder!)
                            // TODO
                        }
                    }, label: {
                        Text("Submit Extra Order")
                    })
                    .buttonStyle(O6NButtonStyle())
                }

                Button(action: {
                    if extraPart == nil {
                        extraPart = MenuView.PendingOrderPart()
                    }
                    showPickerOverlay = true
                }, label: {
                    Text("Add Items to Order")
                })
                .buttonStyle(O6NButtonStyle())
            }
        }
        .navigationTitle("Review Order")
        .onAppear {
//            orderOverview.retreveSubmitedItems(from: activeOrder.selectedOrder!)
        }
        .popover(isPresented: $showPickerOverlay) {
            MenuView(context: .appendedOrder(part: extraPart!))
        }
    }
}

#if DEBUG
struct ActiveOrderOverview_Previews: PreviewProvider {
    typealias Part = RestaurantOrder.OrderPart
    typealias Entry = RestaurantOrder.OrderEntry

    static let items: [MenuItem.ID: MenuItem] = [
        "I1": MenuItem(id: "I1", name: "Item 1", price: 4.99, isAvailable: true,
                       destination: .kitchen, restaurantID: "R", categoryID: "C"),
        "I2": MenuItem(id: "I2", name: "Item 2", price: 9.99, isAvailable: true,
                       destination: .kitchen, restaurantID: "R", categoryID: "C"),
        "I3": MenuItem(id: "I3", name: "Item 3", price: 19.99, isAvailable: true,
                       destination: .kitchen, restaurantID: "R", categoryID: "C"),
    ]
    static let part = Part(entries: [
        Entry(item: items["I1"]!, amount: 2),
        Entry(item: items["I2"]!, amount: 3),
        Entry(item: items["I3"]!, amount: 1),
    ])
    static let order = RestaurantOrder(restaurantID: "R", id: "O", state: .open,
                                       table: "T", placedBy: "U", createdAt: Date(),
                                       parts: [part])

    static var previews: some View {
        NavigationView {
            ActiveOrderDetailView(order: order,
                                zone: Zone(id: "Z", location: "Test Zone", restaurantID: "R"),
                                table: Table(id: "T", name: "Test Table", restaurantID: "R", zoneID: "Z"))
        }
    }
}
#endif
