//
//  KitchenView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 04/05/2021.
//

import SwiftUI

struct KitchenView: View {
    @StateObject var kitchen = KitchenWork()
    @ObservedObject var qrScanner: QrCodeScannerWork
    
    var body: some View {
        VStack{
            List{
                ForEach(kitchen.collectedOrder, id: \.id){ order in
                    VStack{
                        OrderVeiw(orderOverView: order)
                        VStack{
                            ForEach(order.withExtraItems, id:\.id){ extraOrder in
                                Section(header:
                                            HStack{
                                                Text("ExtraOrder: \(extraOrder.extraOrderPart!)")
                                                    .bold()
                                                    .foregroundColor(.red)
                                                
                                                Spacer()
                                            }
                                            .padding(.all, 2)
                                ){
                                    ForEach(extraOrder.withItems, id:\.id){ item in
                                        HStack{
                                            VStack{
                                                HStack{
                                                    Image(systemName: "circle")
                                                        .font(.custom("SF Symbols", size: 7.5))
                                                        .foregroundColor(.white)

                                                    Text(item.itemName)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                }
                                                .padding(.all, 2)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        Section(header:
                                    HStack{
                                        Text("Placed Order: ")
                                            .bold()
                                            .foregroundColor(.red)

                                        Spacer()
                                    }.padding(.all, 2), content: {
                                        ForEach(order.withItems, id: \.id){ item in
                                            OrderItemView(orderItem: item)
                                        }
                                        Button(action: {

                                        }, label: {
                                            Text("Order Completed")
                                                .bold()
                                                .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                                   minHeight: 0, idealHeight: 35, maxHeight: 40,
                                                   alignment: .center)
                                            .foregroundColor(Color(UIColor.systemBackground))
                                            .background(Color(UIColor.label))
                                            .cornerRadius(15)
                                    })
                                    .padding(.all, 5)
                                })
                    }
                    .padding()
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .padding(.top, 10)
        .navigationTitle("\(kitchen.getRestaurantName(fromQrString: qrScanner.restaurantQrCode)): \(qrScanner.kitchen!)")
        .onAppear{
            
            withAnimation(.easeOut(duration: 0.5)){
                kitchen.getKitchenOrder(qrScanner)
            }
        }
    }
}

struct OrderVeiw: View{
    var orderOverView: ClientSubmittedOrder
    
    var body: some View{
        HStack{
            VStack(spacing: 5){
                HStack{
                    Text("Zone: ")
                        .bold()
                        .foregroundColor(.blue)
                    
                    Text(orderOverView.inZone)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack{
                    Text("Table: ")
                        .bold()
                        .foregroundColor(.blue)
                    
                    Text(orderOverView.forTable)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            Spacer()
        }
    }
}

struct OrderItemView: View{
    var orderItem: OrderOverview.OrderOverviewEntry
    
    var body: some View{
        HStack{
            VStack{
                HStack{
                    Image(systemName: "circle")
                        .font(.custom("SF Symbols", size: 7.5))
                        .foregroundColor(.white)
                    
                    Text(orderItem.itemName)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding(.all, 2)
            }
            Spacer()
        }
    }
}

