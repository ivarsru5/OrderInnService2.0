//
//  KitchenOrderOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 07/05/2021.
//

import SwiftUI

struct KitchenOrderOverView: View {
    var order: ClientSubmittedOrder
    
    var body: some View {
        ZStack{
                VStack{
                    HStack{
                        HStack{
                            Text("Table: ")
                                .bold()
                            
                            Text(order.forTable)
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                        }
                    }
                    .padding()
                    
                    VStack{
                        
                        List{
                            ForEach(order.withExtraItems, id: \.id) { order in
                                Section(header: Text("Extra order: \(order.extraOrderPart!)")){
                                    ForEach(order.withItems, id: \.id){ item in
                                        HStack{
                                            Text(item.itemName)
                                                .bold()
                                                .foregroundColor(Color(UIColor.label))

                                            Spacer()

                                            Text("\(item.itemPrice, specifier: "%.2f")EUR")
                                                .italic()
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                    }
                                }
                            }
                            
                            Section(header: Text("Submited item's")){
                                ForEach(order.withItems, id: \.id){ item in
                                    SubmittedOrderCell(itemName: item.itemName, itemPrice: item.itemPrice!)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                    Button(action: {
//                        orderOverview.deleteOrder(fromOrder: activeOrder.selectedOrder!)
//                        activeOrder.collectedOrders.removeAll(where: { $0.id == activeOrder.selectedOrder!.id })
//                        presetationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("order completed")
                            .bold()
                            .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                   minHeight: 0, idealHeight: 45, maxHeight: 55,
                                   alignment: .center)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .background(Color(UIColor.label))
                            .cornerRadius(15)
                    })
                    .padding()
                }
        }
        .navigationTitle(order.inZone)
        .onAppear{
//            orderOverview.markOrderAsRead(forOrder: activeOrder.selectedOrder!)
        }
    }
}
