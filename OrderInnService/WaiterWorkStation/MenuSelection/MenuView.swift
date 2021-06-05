//
//  MenuView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI
import Combine

struct MenuView: View {
    @StateObject var restaurantOrder = RestaurantOrderWork()
    @StateObject var menuOverview = MenuOverViewWork()
    @ObservedObject var table: TableSelectionWork
    @ObservedObject var zone: ZoneWork
    @State var alertitem: AlertItem?
    @State var showOrderCart = false
    
    var body: some View {
        VStack{
            MenuItemView(restaurantOrder: restaurantOrder, menuOverview: menuOverview, showOrderCart: $showOrderCart, alertitem: $alertitem)
            
            .navigationBarItems(trailing: HStack{
                Button(action: {
                    if restaurantOrder.restaurantOrder.menuItems.isEmpty{
                        self.alertitem = UIAlerts.emptyOrder
                    }else{
                        showOrderCart.toggle()
                    }
                }, label: {
                    HStack{
                        Image(systemName: "cart")
                            .font(.custom("SF Symbols", size: 20))
                            .foregroundColor(.blue)

                        Text("\(restaurantOrder.totalPrice, specifier: "%.2f")EUR")
                            .bold()
                            .foregroundColor(Color.blue)
                    }
                })
                .fullScreenCover(isPresented: $showOrderCart){
                    NavigationView{
                        OrderCatView(restaurantOrder: restaurantOrder, dimsissCart: $showOrderCart)
                    }
                }
            })
        }
        .navigationTitle("\(table.selectedTabel!.table)")
        .onAppear{
            menuOverview.getMenuCategory()
            restaurantOrder.restaurantOrder.forTable = table.selectedTabel!.table
            restaurantOrder.restaurantOrder.forZone = zone.selectedZone!.location
        }
        .alert(item: $alertitem){ alert in
            Alert(title: alert.title, message: alert.message, dismissButton: alert.dismissButton)
        }
    }
}

struct MenuItemCell: View{
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
                    restaurantOrder.removeFromOrder(menuItem)
                   self.itemAmount = restaurantOrder.getItemCount(forItem: menuItem)
                }, label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.custom("SF Symbols", size: 30))
                        .foregroundColor(Color(UIColor.label))
                })
                .buttonStyle(PlainButtonStyle())
                
                Text("\(itemAmount)")
                    .foregroundColor(.secondary)
                    .font(.headline)
                
                Button(action: {
                    restaurantOrder.addToOrder(menuItem)
                   self.itemAmount = restaurantOrder.getItemCount(forItem: menuItem)
                }, label: {
                        Image(systemName: "plus.circle.fill")
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

struct MenuItemView: View{
    @ObservedObject var restaurantOrder: RestaurantOrderWork
    @ObservedObject var menuOverview: MenuOverViewWork
    @Binding var showOrderCart: Bool
    @Binding var alertitem: AlertItem?
    
    
    var body: some View{
        List{
            Section(header: Text("Meal's").font(.headline)){
                ForEach(Array(self.menuOverview.menuCategory.enumerated()), id: \.element){ index ,category in
                    Button(action: {
                        self.menuOverview.menuCategory[index].isExpanded.toggle()
                    }, label: {
                        HStack{
                            Text(category.name)
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                            
                            Image(systemName: "arrowtriangle.right.fill")
                                .foregroundColor(Color(UIColor.label))
                                .font(.custom("SF Symbols", fixedSize: 20))
                                .rotationEffect(Angle(degrees: category.isExpanded ? 90 : 0))
                                .animation(.linear(duration: 0.1), value: category.isExpanded)
                        }
                        .padding()
                    })
                    .listRowBackground(Color.secondary)
                    
                    if category.isExpanded{
                        ForEach(category.menuItems, id: \.id) { item in
                            MenuItemCell(restaurantOrder: restaurantOrder, menuOverview: menuOverview, menuItem: item)
                                .padding(.leading, 30)
                        }
                    }
                }
            }
            Section(header: Text("Drinks").font(.headline)){
                ForEach(Array(self.menuOverview.menuDrinks.enumerated()), id: \.element){ index ,category in
                    Button(action: {
                        self.menuOverview.menuDrinks[index].isExpanded.toggle()
                    }, label: {
                        HStack{
                            Text(category.name)
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                            
                            Spacer()
                            
                            Image(systemName: "arrowtriangle.right.fill")
                                .foregroundColor(Color(UIColor.label))
                                .font(.custom("SF Symbols", fixedSize: 20))
                                .rotationEffect(Angle(degrees: category.isExpanded ? 90 : 0))
                                .animation(.linear(duration: 0.1), value: category.isExpanded)
                        }
                        .padding()
                    })
                    .listRowBackground(Color.secondary)
                    
                    if category.isExpanded{
                        ForEach(category.drinks, id: \.id) { item in
                            MenuItemCell(restaurantOrder: restaurantOrder, menuOverview: menuOverview, menuItem: item)
                                .padding(.leading, 30)
                        }
                    }
                }
            }
        }
    }
}
