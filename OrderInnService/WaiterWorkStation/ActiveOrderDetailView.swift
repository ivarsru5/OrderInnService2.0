//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import Combine
import SwiftUI

struct ActiveOrderDetailView: View {
    @EnvironmentObject var menuManager: MenuManager
    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.currentLayout) @Binding var layout: Layout
    @Environment(\.presentationMode) @Binding var presentationMode: PresentationMode
    @State var shouldCloseNotificationPublisher = NotificationCenter.default
        .publisher(for: WaiterTabView.switchToActiveOrdersFlow, object: nil)

    let order: RestaurantOrder

    @State var showPickerOverlay = false
    @State var submittingExtraPartCancellable: AnyCancellable?
    @StateObject var extraPart = MenuView.PendingOrderPart()

    func submitExtraPart() {
        submittingExtraPartCancellable = orderManager
            .addPart(withEntries: extraPart.entries, to: order)
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

    private var extraPartValue: Int {
        if extraPart.isEmpty {
            return 0
        } else {
            return 1
        }
    }
    var body: some View {
        let isSubmitting = submittingExtraPartCancellable != nil

        PopoverHost(baseContent: {
            VStack {
                OrderLocationView(order: order)

                List {
                    if !extraPart.isEmpty {
                        let remove = { (index: OrderPartListing.EntryIndex) in
                            _ = extraPart.entries.remove(at: index)
                        }
                        OrderPartListing(part: extraPart.asOrderPart,
                                         removeEntry: remove)
                    }

                    ForEach(order.parts, id: \.index) { part in
                        OrderPartListing(part: part, removeEntry: nil)
                    }
                }
                .animation(.default, value: extraPart.entries.count)
                .animation(.default, value: order.parts.count)
                .listStyle(InsetGroupedListStyle())

                OrderTotalView(order: order, extraPart: extraPart.asOrderPart)

                HStack {
                    if order.state.isOpen {
                        Button(action: {
                            showPickerOverlay = true
                        }, label: {
                            Text("Add Items to Order")
                        })
                        .buttonStyle(O6NButtonStyle())
                    }

                    if !extraPart.isEmpty {
                        Button(action: submitExtraPart, label: {
                            Text("Submit Extra Part")
                        })
                        .buttonStyle(O6NButtonStyle(isLoading: isSubmitting))
                    }
                }
                .animation(.default, value: !extraPart.isEmpty)
            }
        }, popover: {
            NavigationView {
                MenuView.Wrapper(context: .appendedOrder(part: extraPart))
                    .environmentObject(menuManager)
            }
        }, popoverPresented: $showPickerOverlay)
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.7 : 1.0)
        .animation(.default, value: isSubmitting)
        .overlay(submittingExtraPartOverlay)
        .navigationTitle("Review Order")
        .onReceive(shouldCloseNotificationPublisher) { _ in
            if presentationMode.isPresented {
                presentationMode.dismiss()
            }
        }
    }
}

#if DEBUG
struct ActiveOrderOverview_Previews: PreviewProvider {
    typealias Part = RestaurantOrder.Part
    typealias Entry = RestaurantOrder.Entry
    typealias ID = MenuItem.FullID

    static let restaurant = Restaurant(id: "R", name: "Test Restaurant", subscriptionPaid: true)
    static let menuManager = MenuView_Previews.menuManager
    static let part = Part(index: 0, entries: [
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
            ActiveOrderDetailView(order: order)
                .environment(\.currentLayout, .constant(layout))
                .environmentObject(menuManager)
        }
    }
}
#endif
