//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import SwiftUI

struct ActiveOrderOverview: View {
    @StateObject var orderOverview = ActiveOrderOverviewWork()
    @ObservedObject var activeOrder: ActiveOrderWork
    @State var showMenu = false
    
    var body: some View {
        VStack{
            HStack{
                HStack{
                    Text("Table: ")
                        .bold()
                    
                    Text(activeOrder.selectedOrder!.forTable)
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
                    
//                    ForEach(orderOverview.extraOrders, id:\.index){ extra in
//                        Section(header: Text("Submited extra order: \(extra.index)")){
//                            ForEach(extra.submitedItems, id: \.id){ item in
//                                SubmittedExtraOrderCell(item: item)
//                            }
//                        }
//                    }
                    
                    ForEach(orderOverview.activeExtraOrders, id: \.id){ order in
                        Text(order.id)
                    }
                    
                    Section(header: Text("Submited item's")){
                        ForEach(orderOverview.submitedOrder.withItems, id: \.id){ item in
                            SubmittedOrderCell(itemName: item.itemName, itemPrice: item.itemPrice)
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
                
                Text("EUR\(orderOverview.submitedOrder.totalPrice + orderOverview.extraOrderTotalPrice, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            .padding()
            
            NavigationLink(destination: ExtraItemCategoryView(activeOrderOverview: orderOverview, activeOrder: activeOrder), isActive: $showMenu) { EmptyView() }
            
            HStack{
                if !orderOverview.menuItems.isEmpty{
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)){
                            orderOverview.submitExtraOrder()
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
                    })
                    .padding()
                }
                
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
                })
                .padding()
            }
        }
        .navigationTitle("SelectedZone")
        .navigationBarItems(trailing:
                                HStack{
                                    Button(action: {
                                        self.activeOrder.showActiveOrder.toggle()
                                    }, label: {
                                        Text("Done")
                                            .bold()
                                            .foregroundColor(.blue)
                                    })
                                })
        .onAppear{
            orderOverview.retreveSubmitedIttems(from: activeOrder.selectedOrder!)
        }
    }
}


struct SubmittedOrderCell: View{
    var itemName: String
    var itemPrice: Double
    
    var body: some View{
        HStack{
            Text(verbatim: itemName)
                .bold()
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            Text("\(itemPrice,specifier: "%.2f")EUR")
                .italic()
                .foregroundColor(Color(UIColor.label))
        }
    }
}

struct AddedExtraItemsCell: View{
    @ObservedObject var orderOverview: ActiveOrderOverviewWork
    var item: MenuItem
    
    var body: some View{
        HStack{
            Text(item.name)
                .bold()
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            HStack{
                Text("\(item.price,specifier: "%.2f")EUR")
                    .italic()
                    .foregroundColor(Color(UIColor.label))
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)){
                        orderOverview.removeExtraItem(item)
                    }
                }, label: {
                    Image(systemName: "xmark.circle")
                        .font(.custom("SF Symbols", size: 20))
                        .foregroundColor(.blue)
                })
            }
        }
    }
}

struct SubmittedExtraOrderCell: View{
    var item: MenuItem
    
    var body: some View{
        HStack{
            Text(item.name)
                .bold()
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            Text("\(item.price,specifier: "%.2f")EUR")
                .italic()
                .foregroundColor(Color(UIColor.label))
        }
    }
}
