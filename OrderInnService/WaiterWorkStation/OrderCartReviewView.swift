//
//  OrderCatView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import Combine
import SwiftUI

// TODO[pn 2021-07-20]: This is similar enough to ActiveOrderDetailView such
// that I reckon they can be merged into one view struct to simplify
// maintenance.
struct OrderCartReviewView: View {
    typealias PendingOrderPart = MenuView.PendingOrderPart

    class Model: ObservableObject {
        @Published var isSending = false
        @Published var createdOrder: RestaurantOrder?

        func sendOrder(for table: Table, from part: PendingOrderPart) {
            let authManager = AuthManager.shared
            let restaurant = authManager.restaurant!
            let waiter = authManager.waiter!

            isSending = true
            var sub: AnyCancellable?
            sub = RestaurantOrder.create(under: restaurant, placedBy: waiter, forTable: table, withEntries: part.entries)
                .mapError { error in
                    // TODO[pn 2021-07-20]
                    fatalError("FIXME Failed to create order: \(String(describing: error))")
                }
                .sink { [unowned self] order in
                    isSending = false
                    createdOrder = order
                    // ...?
                    if let _ = sub {
                        sub = nil
                    }
                }
        }
    }

    @ObservedObject var part: PendingOrderPart
    @EnvironmentObject var authManager: AuthManager
    let table: Table
    @Environment(\.currentRestaurant) var restaurant: Restaurant!

    #if DEBUG
    @StateObject var model: Model
    #else
    @StateObject var model = Model()
    #endif

    init(part: PendingOrderPart, table: Table) {
        self._part = ObservedObject(wrappedValue: part)
        self.table = table
        #if DEBUG
        self._model = StateObject(wrappedValue: Model())
        #endif
    }

    #if DEBUG
    init(part: PendingOrderPart, table: Table, model: Model) {
        self._part = ObservedObject(wrappedValue: part)
        self.table = table
        self._model = StateObject(wrappedValue: model)
    }
    #endif

    @ViewBuilder var sendingOverlay: some View {
        if model.isSending {
            Spinner()
        } else {
            EmptyView()
        }
    }
    var body: some View {
        let dummyOrder = RestaurantOrder(
            restaurantID: restaurant.id, id: "(dummy)", state: .open,
            table: table.fullID, placedBy: authManager.waiter!.id,
            createdAt: Date(), parts: [])

        OrderDetailView.Wrapper(order: dummyOrder, extraPart: part, buttons: {
            Button(action: {
                model.sendOrder(for: table, from: part)
            }, label: {
                Text("Send Order")
            })
            .buttonStyle(O6NButtonStyle())
        })
        .opacity(model.isSending ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: model.isSending)
        .overlay(sendingOverlay)
        .navigationBarTitle("Order", displayMode: .large)
    }
}

#if DEBUG
struct OrderCartReviewView_Previews: PreviewProvider {
    typealias Entry = RestaurantOrder.OrderEntry
    typealias ID = MenuItem.FullID

    class MockModel: OrderCartReviewView.Model {
        override func sendOrder(for table: Table, from part: OrderCartReviewView.PendingOrderPart) {
            isSending = true
        }
    }

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let employee = Restaurant.Employee(restaurantID: restaurant.id, id: "E",
                                              name: "Test", lastName: "Employee",
                                              manager: false, isActive: false)

    static let layout = Layout(autoZones: [
        Zone(id: "Z", location: "Test Zone", restaurantID: restaurant.id),
    ], autoTables: [
        Table(id: "T", name: "Test Table", restaurantID: restaurant.id, zoneID: "Z")
    ])

    static let menuManager = MenuManager(debugForRestaurant: restaurant, withAutoMenu: [
        MenuItem(id: "I1", name: "Item 1", price: 4.99, isAvailable: true,
                 destination: .kitchen, restaurantID: "R", categoryID: "C"),
        MenuItem(id: "I2", name: "Item 2", price: 4.99, isAvailable: true,
                 destination: .kitchen, restaurantID: "R", categoryID: "C"),
        MenuItem(id: "I3", name: "Item 3", price: 4.99, isAvailable: true,
                 destination: .kitchen, restaurantID: "R", categoryID: "C"),
    ], autoCategories: [
        MenuCategory(id: "C", name: "Test Category", type: .food, restaurantID: restaurant.id),
    ])

    static let authManager = AuthManager(debugWithRestaurant: restaurant,
                                         waiter: employee, kitchen: nil)

    static let model = MockModel()

    static var part: MenuView.PendingOrderPart {
        let part = MenuView.PendingOrderPart(menuManager: menuManager)
        part.entries = [
            Entry(itemID: ID(string: "C/I1")!, amount: 2),
            Entry(itemID: ID(string: "C/I2")!, amount: 3),
            Entry(itemID: ID(string: "C/I3")!, amount: 1),
        ]
        return part
    }

    static var previews: some View {
        OrderCartReviewView(part: part, table: layout.tables.first!.value, model: model)
            .environment(\.currentRestaurant, restaurant)
            .environment(\.currentLayout, .constant(layout))
            .environmentObject(authManager)
            .environmentObject(menuManager)
    }
}
#endif
