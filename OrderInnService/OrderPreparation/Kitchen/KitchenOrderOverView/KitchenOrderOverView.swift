//
//  KitchenOrderOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import SwiftUI
import FirebaseFirestore

#if false
struct KitchenOrderOverView: View {
    let order: RestaurantOrder
    let zone: Zone
    let table: Table
    let menu: [MenuItem.ID: MenuItem]

    struct OrderPartListing: View {
        struct Cell: View {
            let entry: RestaurantOrder.OrderEntry

            var body: some View {
                HStack {
                    Text(entry.item.name)
                        .bold()
                        .foregroundColor(Color.label)
                    Text(" ×\(entry.amount)")
                        .foregroundColor(Color.secondary)

                    Spacer()

                    Text("\(entry.subtotal, specifier: "%.2f") EUR")
                        .foregroundColor(Color.label)
                }
            }

        }

        let partIndex: Int
        let part: RestaurantOrder.OrderPart
        var headerText: String {
            if partIndex == 0 {
                return "Initial Order"
            } else {
                return "Extra Order: \(partIndex)"
            }
        }

        var body: some View {
            Section(header: Text(headerText)) {
                ForEach(part.entries.indices) { entryIndex in
                    Cell(entry: part.entries[entryIndex])
                }
            }
        }
    }
    
    func markOrderAsReady(forOrder: ClientSubmittedOrder){
        Firestore.firestore()
            .collection("Restaurants").document(UserDefaults.standard.kitchenQrStringKey)
            .collection("Order")
            .document(forOrder.id)
            .updateData([
                "orderReady" : true
            ]) { error in
                if let err = error{
                    print("Error updating document \(err)")
                }else{
                    print("Order prepered!")
            }
        }
    }
    
    var body: some View {
        ZStack{
                VStack {
                    HStack {
                        Text("Table: ")
                            .bold()

                        Text(table.name)
                            .foregroundColor(Color.label)

                        Spacer()
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
                        // TODO[pn 2021-07-16]
//                        orderOverview.deleteOrder(fromOrder: activeOrder.selectedOrder!)
//                        activeOrder.collectedOrders.removeAll(where: { $0.id == activeOrder.selectedOrder!.id })
//                        presetationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Mark Order as Completed")
                            .bold()
                            .frame(width: nil, height: 45, alignment: .center)
                            .foregroundColor(Color.systemBackground)
                            .background(Color.label)
                            .cornerRadius(15)
                    })
                    .padding()
                }
        }
        .navigationTitle(zone.location)
        .onAppear{
            // TODO[pn 2021-07-16]
//            orderOverview.markOrderAsRead(forOrder: activeOrder.selectedOrder!)
        }
    }
}
#endif
