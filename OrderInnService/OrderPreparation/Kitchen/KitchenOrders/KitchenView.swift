//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import Combine
import SwiftUI

struct KitchenView: View {
    var body: some View {
        Text("Placeholder for refactoring")
    }
}
#if false
struct KitchenView: View {
    class Model: ObservableObject {
        @Published var isLoading = true
        @Published var orders: [RestaurantOrder] = []
        @Published var tables: [Table.ID: Table] = [:]
        @Published var zones: [Zone.ID: Zone] = [:]

        init() {

        }
    }

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var orderManager: RestaurantOrderManager

    struct OrderCell: View {
        @Binding var order: RestaurantOrder
        @Binding var zone: Zone
        @Binding var table: Table

        var zoneLabelColor: Color {
            order.state == .new ? Color.red : Color.label
        }
        var body: some View {
            NavigationLink(destination: KitchenOrderOverView(order: order)) {
                HStack {
                    Text("In Zone: \(zone.name)")
                        .bold()
                        .foregroundColor(zoneLabelColor)
                    Spacer()
                    Text("Table: \(table.name)")
                        .bold()
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    var body: some View {
        ZStack{
            if !kitchen.collectedOrders.isEmpty {
                List {
                    Section(header: Text("Received Orders")){
                        ForEach(kitchen.collectedOrders, id: \.id) { order in
                            OrderCell(order: order)
                        }
                        .padding()
                    }
                }
            } else {
                Text("There have not been placed any order yet.")
                    .font(.headline)
                    .foregroundColor(.label)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle("\(authManager.restaurant.name): \(authManager.kitchen!)")
    }
}

#endif
