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

    struct ItemCell: View {
        let entry: RestaurantOrder.OrderEntry
        @Binding var amount: Int

        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .symbolSize(10)

                Text(entry.item.name)
                    .bold()
                Text(" ×\(entry.amount)")
                    .foregroundColor(Color.secondary)

                Spacer()

                Text("\(entry.subtotal, specifier: "%.2f") EUR")

                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        amount = 0
                    }
                }, label: {
                    Image(systemName: "xmark.circle")
                        .symbolSize(20)
                        .foregroundColor(.blue)
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    struct OrderListing: View {
        @ObservedObject var part: PendingOrderPart
        var body: some View {
            List {
                Section(header: Text("Selected Items")) {
                    ForEach(part.entries, id: \.itemID) { entry in
                        ItemCell(entry: entry,
                                 amount: part.amountBinding(for: entry.item))
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }

    struct OrderView: View {
        @ObservedObject var part: PendingOrderPart
        let sendOrder: () -> ()

        var body: some View {
            VStack {
                OrderListing(part: part)

                HStack {
                    Text("Total Order Amount:")
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(part.subtotal, specifier: "%.2f") EUR")
                        .bold()
                }
                .padding()

                Button(action: sendOrder, label: {
                    Text("Send Order")
                })
                .buttonStyle(O6NButtonStyle())
            }
        }
    }

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
    @StateObject var model = Model()

    @ViewBuilder var sendingOverlay: some View {
        if model.isSending {
            Spinner()
        } else {
            EmptyView()
        }
    }
    var body: some View {
        OrderView(part: part, sendOrder: { })
            .opacity(model.isSending ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: model.isSending)
            .overlay(sendingOverlay)
            .navigationTitle(Text("Order"))
    }
}

#if DEBUG
struct OrderCartReviewView_Previews: PreviewProvider {
    typealias Entry = RestaurantOrder.OrderEntry

    class MockModel: OrderCartReviewView.Model {
        override func sendOrder(for table: Table, from part: OrderCartReviewView.PendingOrderPart) {
            isSending = true
//            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(3))) {
//                [self] in
//                createdOrder = RestaurantOrder(restaurantID: "R", id: "O", state: .new,
//                                               table: table.id, placedBy: "E",
//                                               createdAt: Date(), parts: [part.asOrderPart()])
//                isSending = false
//            }
        }
    }

    static let items: [MenuItem.ID: MenuItem] = [
        "I1": MenuItem(id: "I1", name: "Item 1", price: 4.99, isAvailable: true,
                       destination: .kitchen, restaurantID: "R", categoryID: "C"),
        "I2": MenuItem(id: "I2", name: "Item 2", price: 4.99, isAvailable: true,
                       destination: .kitchen, restaurantID: "R", categoryID: "C"),
        "I3": MenuItem(id: "I3", name: "Item 3", price: 4.99, isAvailable: true,
                       destination: .kitchen, restaurantID: "R", categoryID: "C"),
    ]

    static func makeAuthManager() -> AuthManager {
        return AuthManager(debugWithRestaurant: Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true),
                    waiter: .init(restaurantID: "R", id: "E", name: "Test", lastName: "Employee", manager: false, isActive: false),
                    kitchen: nil)
    }

    static func makeModel() -> OrderCartReviewView.Model {
        return MockModel()
    }

    static func makePart() -> MenuView.PendingOrderPart {
        let part = MenuView.PendingOrderPart()
        part.entries = [
            Entry(item: items["I1"]!, amount: 2),
            Entry(item: items["I2"]!, amount: 3),
            Entry(item: items["I3"]!, amount: 1),
        ]
        return part
    }

    static var previews: some View {
        OrderCartReviewView(part: makePart(), model: makeModel())
            .environmentObject(makeAuthManager())
    }
}
#endif
