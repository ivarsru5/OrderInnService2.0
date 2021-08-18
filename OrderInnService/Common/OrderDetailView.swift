//
//  OrderDetailView.swift
//  OrderInnService
//
//  Created by paulsnar on 8/10/21.
//

import Combine
import Foundation
import SwiftUI

struct OrderLocationView: View {
    private enum Data {
        case order(RestaurantOrder)
        case location(Zone?, Table)
    }

    @Environment(\.currentLayout) @Binding var layout: Layout
    private let data: Data

    init(order: RestaurantOrder) {
        self.data = .order(order)
    }
    init(zone: Zone?, table: Table) {
        self.data = .location(zone, table)
    }

    private var zone: Zone {
        switch self.data {
        case .order(let order): return layout.zones[order.tableFullID.zone]!
        case .location(let maybeZone, let table):
            if let zone = maybeZone {
                return zone
            } else {
                return layout.zones[table.zoneID]!
            }
        }
    }
    private var table: Table {
        switch self.data {
        case .order(let order): return layout.tables[order.tableFullID]!
        case .location(_, let table): return table
        }
    }

    var body: some View {
        HStack {
            Text("Zone: ").bold() + Text(zone.location)
            Spacer()
            Text("Table: ").bold() + Text(table.name)
        }
        .padding([.leading, .trailing])
    }
}

struct OrderTotalView: View {
    @EnvironmentObject var menuManager: MenuManager
    let order: RestaurantOrder?
    let extraPart: RestaurantOrder.Part?
    private var newTotal: Currency? {
        guard order != nil, let part = extraPart, !part.entries.isEmpty else {
            return nil
        }
        return baseTotal + part.subtotal(using: menuManager.menu)
    }
    private var baseTotal: Currency {
        var total = Currency(0)
        if let order = self.order {
            total += order.total(using: menuManager.menu)
        } else if let part = extraPart {
            total += part.subtotal(using: menuManager.menu)
        }
        return total
    }

    var body: some View {
        HStack {
            Text("Total Order Amount:").foregroundColor(.secondaryLabel)
            Spacer()
            IfLet(newTotal, whenPresent: { newTotal in
                Group {
                    Text("EUR \(baseTotal, specifier: "%.2f")")
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.secondary)
                Text("EUR \(newTotal, specifier: "%.2f")").bold()
            }, whenAbsent: {
                Text("EUR \(baseTotal, specifier: "%.2f")").bold()
            })
        }
        .padding([.leading, .trailing])
    }
}

struct OrderPartListing: View {
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

    typealias PartIndex = RestaurantOrder.Part.Index
    typealias EntryIndex = Array<RestaurantOrder.Entry>.Index
    @EnvironmentObject var menuManager: MenuManager
    let part: RestaurantOrder.Part
    let removeEntry: ((EntryIndex) -> ())?

    func bindRemover(for entry: EntryIndex) -> (() -> ())? {
        guard let removeEntry = self.removeEntry else { return nil }
        return { removeEntry(entry) }
    }

    private var header: Text {
        switch part.index {
        case PartIndex.IMAGINARY: return Text("Selected Items")
        case PartIndex.INITIAL: return Text("Initial Order")
        default: return Text("Extra Order \(part.index)")
        }
    }
    var body: some View {
        Section(header: header) {
            let entries = Array(part.entries.enumerated())
            ForEach(entries, id: \.element.itemID) { enumEntry in
                let entry = enumEntry.element
                let item = menuManager.menu[entry.itemID]!
                let remove = bindRemover(for: enumEntry.offset)
                EntryCell(item: item, entry: entry, remove: remove)
            }
        }
    }
}

#if DEBUG && false
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
