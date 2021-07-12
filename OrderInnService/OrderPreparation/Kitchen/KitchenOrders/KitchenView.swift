//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import SwiftUI

struct KitchenView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var kitchen = KitchenWork()
    
    var body: some View {
        ZStack{
            if !kitchen.collectedOrders.isEmpty{
                List{
                    Section(header: Text("Recived Orders")){
                        ForEach(kitchen.collectedOrders, id: \.id) { order in
                            NavigationLink(destination: KitchenOrderOverView(order: order)) {
                                HStack{
                                    HStack{
                                        Text("In Zone: ")
                                            .bold()
                                            .foregroundColor(order.orderOpened ? Color(UIColor.label) : Color.red)
                                        
                                        Text(order.inZone)
                                            .bold()
                                            .foregroundColor(order.orderOpened ? Color(UIColor.label) : Color.red)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack{
                                        Text("Table: ")
                                            .bold()
                                            .foregroundColor(.secondary)
                                        
                                        Text(order.forTable)
                                            .bold()
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }else{
                Text("There have not been placed any order yet.")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle("\(authManager.restaurant.name): \(authManager.kitchen!)")
    }
}

