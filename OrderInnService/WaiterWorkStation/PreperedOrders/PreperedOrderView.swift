//
//  PreperedOrderView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/07/2021.
//

import SwiftUI

struct PreperedOrderView: View {
    @Environment (\.presentationMode) var presentationMode
    @ObservedObject var preperedOrders: ActiveOrderWork
    @StateObject var orderOverview = ActiveOrderOverviewWork()
    @State var showMenu = false
    
    var body: some View {
        ZStack{
            if !orderOverview.sendingQuery{
                VStack{
                    HStack{
                        HStack{
                            Text("Table: ")
                                .bold()
                            
                            Text(preperedOrders.selectedOrder!.forTable)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    VStack{
                        List{
                            if !orderOverview.menuItems.isEmpty{
                                Section(header: Text("Selected extra item's")){
                                    ForEach(orderOverview.menuItems, id:\.id){ item in
                                        AddedExtraItemsCell(orderOverview: orderOverview, item: item)
                                    }
                                }
                            }else{
                                EmptyView()
                            }
                            
                            ForEach(orderOverview.collectedOrder.withExtraItems, id: \.id){ order in
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
                                ForEach(orderOverview.collectedOrder.withItems, id: \.id){ item in
                                    SubmittedOrderCell(itemName: item.itemName, itemPrice: item.itemPrice!)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                    
                    HStack{
                        Text("Total Order Amount")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("EUR\(orderOverview.totalCollectedOrderPrice, specifier: "%.2f")")
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                    }
                    .padding()
                    
                    NavigationLink(destination: ExtraItemCategoryView(activeOrderOverview: orderOverview , activeOrder: preperedOrders), isActive: $showMenu) { EmptyView() }
                    
                    HStack{
                        if !orderOverview.menuItems.isEmpty{
                            
                            //After new extra coming in play the order should go back to active orders
                            //and in be diplayed in kitchen.
                            //And all other parts should be marked as finished, so not to confuse the kitchen staff.
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.5)){
                                    orderOverview.submitExtraOrder(from: preperedOrders.selectedOrder!)
                                }
                            }, label: {
                                Text("Submit extra order")
                                    .bold()
                                    .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                           minHeight: 0, idealHeight: 32, maxHeight: 54,
                                           alignment: .center)
                                    .foregroundColor(Color(UIColor.systemBackground))
                                    .background(Color(UIColor.label))
                                    .cornerRadius(15)
                                    .multilineTextAlignment(.center)
                            })
                        }
                        //After sending the check the order need to be placed in finished orders
                        //only available to manager, so he can give status to it 'closed'
                        Button(action: {
                            //TODO: Add functionality to send check via sms.
                        }, label: {
                            Text("Send check via message")
                                .bold()
                                .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                       minHeight: 0, idealHeight: 32, maxHeight: 54,
                                       alignment: .center)
                                .foregroundColor(Color(UIColor.systemBackground))
                                .background(Color(UIColor.label))
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                        })
                        
                        Button(action: {
                            self.showMenu.toggle()
                        }, label: {
                            Text("Add items to Order")
                                .bold()
                                .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity,
                                       minHeight: 0, idealHeight: 32, maxHeight: 54,
                                       alignment: .center)
                                .foregroundColor(Color(UIColor.systemBackground))
                                .background(Color(UIColor.label))
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                        })
                    }
                    .padding(10)
                }
            }else{
                Spinner()
            }
        }
        .navigationTitle(preperedOrders.selectedOrder!.forZone)
        .navigationBarItems(trailing:
                                HStack{
                                    Button(action: {
                                        self.presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Text("Done")
                                            .bold()
                                            .foregroundColor(.blue)
                                    })
                                })
        .onAppear{
            orderOverview.retreveSubmitedItems(from: preperedOrders.selectedOrder!)
        }
    }
}
