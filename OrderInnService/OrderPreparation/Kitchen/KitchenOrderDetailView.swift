//
//  KitchenOrderOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import Combine
import SwiftUI

struct KitchenOrderDetailView: View {
    @EnvironmentObject var menuManager: MenuManager
    @EnvironmentObject var orderManager: OrderManager
    let order: RestaurantOrder
    @State var markOrderCompleteCancellable: AnyCancellable?
    @Environment(\.presentationMode) @Binding var presentationMode: PresentationMode

    @State var selection = Set<RestaurantOrder.EntryReference>()
    @State var selectionEnabled = false

    func markOrderSeen() {
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

    struct FulfilledSelectionView: View {
        typealias Ref = RestaurantOrder.EntryReference

        struct Cell: View {
            let entry: RestaurantOrder.Entry
            let item: MenuItem
            @Binding var included: Bool

            var body: some View {
                HStack {
                    if included {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.link)
                            .bodyFont(size: 20)
                    } else if entry.isFulfilled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.secondary)
                            .bodyFont(size: 20)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.link)
                            .bodyFont(size: 20)
                    }
                    Text(item.name).bold()
                    Text(" ×\(entry.amount)").foregroundColor(.secondary)
                    Spacer()
                }
                .animation(.linear(duration: 0.05), value: included)
                .disabled(entry.isFulfilled)
                .opacity(entry.isFulfilled ? 0.5 : 1.0)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !entry.isFulfilled {
                        included.toggle()
                    }
                }
            }
        }

        let order: RestaurantOrder
        @State var selection = Set<Ref>()
        @State var updatingCancellable: AnyCancellable?
        @Environment(\.presentationMode) @Binding var presentationMode: PresentationMode
        @EnvironmentObject var menuManager: MenuManager
        @EnvironmentObject var orderManager: OrderManager

        func binding(for entry: Ref) -> Binding<Bool> {
            return Binding(get: {
                return selection.contains(entry)
            }, set: { newValue in
                if newValue {
                    selection.insert(entry)
                } else {
                    selection.remove(entry)
                }
            })
        }

        func section(for part: RestaurantOrder.Part) -> some View {
            let header = part.index == 0 ? Text("Initial Order") : Text("Extra Order \(part.index)")
            return Section(header: header) {
                ForEach(Array(part.entries.indices), id: \.self) { index in
                    let entry = part.entries[index]
                    let ref = Ref(part: part.index, entry: index)
                    let item = menuManager.menu[entry.itemID]!
                    Cell(entry: entry, item: item,
                         included: binding(for: ref))
                        .disabled(updatingCancellable != nil)
                }
            }
        }

        func markComplete() {
            let entries = Array(selection)
            updatingCancellable = orderManager.update(order: order,
                                                      markFulfilled: entries)
                .mapError { error in
                    // TODO[pn 2021-08-17]
                    fatalError("FIXME Failed to mark order parts as fulfilled: \(String(describing: error))")
                }
                .ignoreOutput()
                .sink(receiveCompletion: { _ in
                    if presentationMode.isPresented {
                        presentationMode.dismiss()
                    }
                    if let _ = updatingCancellable {
                        updatingCancellable = nil
                    }
                })
        }

        var body: some View {
            VStack {
                List {
                    ForEach(order.parts, id: \.index) { part in
                        section(for: part)
                    }
                }
                .listStyle(InsetGroupedListStyle())

                HStack {
                    Button(action: {
                        if presentationMode.isPresented {
                            presentationMode.dismiss()
                        }
                    }, label: {
                        Text("Cancel")
                    })
                    .buttonStyle(O6NMutedButtonStyle())

                    Button(action: {
                        markComplete()
                    }, label: {
                        Text("Mark Selected as Complete")
                    })
                    .disabled(selection.isEmpty)
                    .buttonStyle(O6NButtonStyle(isLoading: updatingCancellable != nil,
                                                isEnabled: !selection.isEmpty))
                    .animation(O6NButtonStyle.transitionAnimation, value: selection.isEmpty)
                    .animation(O6NButtonStyle.transitionAnimation, value: updatingCancellable != nil)
                }
            }
        }
    }

    var canMarkItemsAsComplete: Bool {
        return order.state.isOpen && !order.parts.allSatisfy({ $0.isFulfilled })
    }
    @ViewBuilder var buttons: some View {
        if canMarkItemsAsComplete {
            Button(action: {
                selectionEnabled = true
            }, label: {
                Text("Mark Items as Complete")
            })
            .buttonStyle(O6NButtonStyle())
        }
    }
    var body: some View {
        VStack {
            OrderLocationView(order: order)

            List {
                ForEach(order.parts, id: \.index) { part in
                    OrderPartListing(part: part, removeEntry: nil)
                }
            }
            .listStyle(InsetGroupedListStyle())

            OrderTotalView(order: order, extraPart: nil)
                .padding(canMarkItemsAsComplete ? [] : [.bottom])

            HStack {
                buttons
            }
        }
        .fullScreenCover(isPresented: $selectionEnabled) {
            FulfilledSelectionView(order: order)
        }
        .navigationBarTitle(Text("Review Order"), displayMode: .inline)
        .onAppear {
            if order.state == .new {
                markOrderSeen()
            }
        }
    }
}

#if DEBUG
struct KitchenOrderDetailView_Previews: PreviewProvider {
    typealias Order = RestaurantOrder
    typealias Part = RestaurantOrder.Part
    typealias Entry = RestaurantOrder.Entry
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
    static let layout = Layout(zones: [ zone.id: zone ], tables: [ table.fullID: table ])
    static let order = Order(
        restaurantID: restaurant.id, id: "O", state: .open, table: table.fullID,
        placedBy: "E", createdAt: Date(),
        parts: [
            Part(index: 0, entries: [
                Entry(itemID: ItemID(category: "C", item: "I1"), amount: 5),
                Entry(itemID: ItemID(category: "C", item: "I2"), amount: 4),
            ]),
            Part(index: 1, entries: [
                Entry(itemID: ItemID(category: "C", item: "I1"), amount: 3),
                Entry(itemID: ItemID(category: "C", item: "I2"), amount: 2),
            ]),
            Part(index: 2, entries: [
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

    static var previews: some View {
        Group {
            KitchenOrderDetailView(order: orderManager.orders.first!)
        }
        .environment(\.currentRestaurant, restaurant)
        .environment(\.currentLayout, .constant(layout))
        .environmentObject(menuManager)
        .environmentObject(orderManager as OrderManager)
    }
}
#endif
