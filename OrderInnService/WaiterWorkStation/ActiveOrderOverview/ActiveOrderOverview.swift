//
//  ActiveOrderEdidView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 27/04/2021.
//

import SwiftUI

struct ActiveOrderOverview: View {
    @StateObject var orderOverview = ActiveOrderOverviewWork()
    @StateObject var restaurantOrder = RestaurantOrderWork()
    @ObservedObject var activeOrder: ActiveTableWork
    @State var displayActionSheet = false
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
            
            List{
                Section(header: Text("Submited Item's")){
                    ForEach(orderOverview.submitedOrder.withItems, id: \.id){ item in
                        HStack{
                            Text(item.itemName)
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                            
                            Text("\(item.itemPrice,specifier: "%.2f")EUR")
                                .italic()
                                .foregroundColor(Color(UIColor.label))
                        }
                    }
                }
            }
            
            HStack{
                Text("Total Order Amount")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Spacer()
                
                Text("EUR\(orderOverview.submitedOrder.totalPrice, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            .padding()
            
            NavigationLink(destination: AddMenuItem(activeOrder: activeOrder, restaurantOrder: restaurantOrder), isActive: $showMenu) { EmptyView() }
            
            Button(action: {
                self.showMenu.toggle()
            }, label: {
                Text("Add items to Order")
                    .bold()
                    .frame(width: 300, height: 50, alignment: .center)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .background(Color(UIColor.label))
                    .cornerRadius(15)
            })
            .padding()
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
        .actionSheet(isPresented: $displayActionSheet, content: {
            let buttons: [ActionSheet.Button] = [
                .default(Text("Add more Items"), action: { self.showMenu.toggle() }),
                .cancel({ self.displayActionSheet.toggle() })
            ]
            return ActionSheet(title: Text("Edit Options"), buttons: buttons)
        })
    }
}

struct AddMenuItem: View{
    @ObservedObject var menuOverView = MenuOverViewWork()
    @ObservedObject var activeOrder: ActiveTableWork
    @ObservedObject var restaurantOrder: RestaurantOrderWork
    
    var body: some View{
        VStack{
            List{
                ForEach(menuOverView.menuCategory, id:\.id){ category in
                    Button(action: {
                        self.menuOverView.category = category
                        self.menuOverView.getMenuItems(with: category)
                    }, label: {
                        Text(category.name)
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                    })
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle(activeOrder.selectedOrder!.forTable)
        .navigationBarItems(trailing:
                                HStack{
                                    Button(action: {
                                       _ = self.restaurantOrder.groupCourse(fromItems: restaurantOrder.restaurantOrder.menuItems)
                                    }, label: {
                                        Text("Done")
                                            .bold()
                                            .foregroundColor(.blue)
                                    })
                                })
        .sheet(isPresented: $menuOverView.presentMenu){
            AddMenuItemView(restaurantOrder: restaurantOrder, menuOverView: menuOverView, dismissMenu: $menuOverView.presentMenu)
        }
        .onAppear{
            menuOverView.getMenuCategory()
        }
    }
}

struct AddMenuItemView: View{
    @ObservedObject var restaurantOrder: RestaurantOrderWork
    @ObservedObject var menuOverView: MenuOverViewWork
    @Binding var dismissMenu: Bool
    
    var body: some View{
        VStack{
            HStack{
                HStack{
                    Image(systemName: "cart")
                        .font(.custom("SFSymbols", size: 20))
                        .foregroundColor(.blue)
                    
                    Text("\(restaurantOrder.totalPrice, specifier: "%.2f")EUR")
                        .italic()
                        .foregroundColor(.blue)
                }
                Spacer()
                
                Button(action: {
                    dismissMenu.toggle()
                }, label: {
                    Text("Done")
                        .bold()
                        .foregroundColor(.blue)
                })
            }
            .padding()
            
            VStack{
                Text(menuOverView.category!.name)
                    .bold()
                    .foregroundColor(Color(UIColor.label))
                    .font(.headline)
                
                List{
                    ForEach(menuOverView.menuItems, id: \.name){ item in
                        AddMenuItemCell(restaurantOrder: restaurantOrder, menuOverview: menuOverView, menuItem: item)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
}

struct AddMenuItemCell: View{
    @ObservedObject var restaurantOrder: RestaurantOrderWork
    @ObservedObject var menuOverview: MenuOverViewWork
    @State var itemAmount = 0
    var menuItem: MenuItem
    
    var body: some View{
        
        HStack{
            Image(systemName: "circle.fill")
                .font(.custom("SF Symbols", size: 10))
                .foregroundColor(Color(UIColor.label))
            
            Text(menuItem.name)
                .bold()
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            HStack{
                Button(action: {
                    restaurantOrder.removeFromExtraOrder(menuItem)
                   self.itemAmount = restaurantOrder.getItemCount(forItem: menuItem)
                }, label: {
                    Image(systemName: "minus.rectangle.fill")
                        .font(.custom("SF Symbols", size: 30))
                        .foregroundColor(Color(UIColor.label))
                })
                .buttonStyle(PlainButtonStyle())
                
                Text("\(itemAmount)")
                    .foregroundColor(.secondary)
                    .font(.headline)
                
                Button(action: {
                    restaurantOrder.addExtraOrder(menuItem)
                   self.itemAmount = restaurantOrder.getItemCount(forItem: menuItem)
                }, label: {
                        Image(systemName: "plus.rectangle.fill")
                            .font(.custom("SF Symbols", size: 30))
                            .foregroundColor(Color(UIColor.label))
                    })
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.all, 5)
        .onAppear{
            self.itemAmount = restaurantOrder.getItemCount(forItem: menuItem)
        }
    }
}
