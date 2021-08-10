//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Combine
import SwiftUI

struct ActiveOrderDetailView: View {
    @EnvironmentObject var orderManager: OrderManager
    let order: RestaurantOrder
    @StateObject var extraPart: MenuView.PendingOrderPart
    @State var showPickerOverlay = false
    @State var submittingExtraPartCancellable: AnyCancellable?

    fileprivate init(menuManager: MenuManager, order: RestaurantOrder) {
        self.order = order

        self._extraPart = StateObject(
            wrappedValue: MenuView.PendingOrderPart(menuManager: menuManager))
    }
    struct Wrapper: View {
        @EnvironmentObject var menuManager: MenuManager
        let order: RestaurantOrder

        var body: ActiveOrderDetailView {
            ActiveOrderDetailView(menuManager: menuManager, order: order)
        }
    }

    func submitExtraPart() {
        let part = extraPart.asOrderPart()
        submittingExtraPartCancellable = orderManager.addPart(part, to: order)
            .mapError { error in
                // TODO[pn 2021-08-06]
                fatalError("FIXME Failed to add new order part: \(String(describing: error))")
            }
            .ignoreOutput()
            .sink(receiveCompletion: { _ in
                extraPart.clear()
                if let _ = submittingExtraPartCancellable {
                    submittingExtraPartCancellable = nil
                }
            })
    }

    @ViewBuilder var submittingExtraPartOverlay: some View {
        if submittingExtraPartCancellable != nil {
            Spinner()
        } else {
            EmptyView()
        }
    }

    var body: some View {
        let isSubmitting = submittingExtraPartCancellable != nil

        OrderDetailView.Wrapper(order: order, extraPart: extraPart, buttons: {
            Button(action: {
                showPickerOverlay = true
            }, label: {
                Text("Add Items to Order")
            })
            .buttonStyle(O6NButtonStyle())

            if !extraPart.entries.isEmpty {
                Button(action: submitExtraPart, label: {
                    Text("Submit Extra Part")
                })
                .buttonStyle(O6NButtonStyle(isLoading: isSubmitting))
            }
        })
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.7 : 1.0)
        .animation(.default, value: isSubmitting)
        .overlay(submittingExtraPartOverlay)
        .navigationTitle("Review Order")
        .popover(isPresented: $showPickerOverlay) {
            NavigationView {
                MenuView.Wrapper(context: .appendedOrder(part: extraPart))
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
    static let menuManager = MenuView_Previews.menuManager
    static let part = Part(entries: [
        Entry(itemID: ID(category: "breakfast", item: "1"), amount: 2),
        Entry(itemID: ID(category: "breakfast", item: "2"), amount: 3),
        Entry(itemID: ID(category: "drinks", item: "1"), amount: 1),
    ])
    static let layout = Layout(autoZones: [
        Zone(id: "Z", location: "Test Zone", restaurantID: "R"),
    ], autoTables: [
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
