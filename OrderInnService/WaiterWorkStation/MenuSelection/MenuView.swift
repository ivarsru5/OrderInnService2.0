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
    @State var showOrder = false
    @State var showOrderCart = false
    @State var expandMenu = false
    
    var body: some View {
        VStack{
            List{
                ForEach(Array(self.menuOverview.menuCategory.enumerated()), id: \.element){ index ,category in
                    Button(action: {
                        self.menuOverview.menuCategory[index].isExpanded.toggle()
                    }, label: {
                        Text(category.name)
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                    })
                    if category.isExpanded{
                        ForEach(category.menuItems, id: \.id) { item in
                            MenuItemCell(restaurantOrder: restaurantOrder, menuOverview: menuOverview, menuItem: item)
                                .padding(.leading, 10)
                        }
                    }
                }
            }
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
