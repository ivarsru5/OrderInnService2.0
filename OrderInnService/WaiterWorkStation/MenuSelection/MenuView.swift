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
    @State var alertitem: AlertItem?
    @State var showOrder = false
    @State var showOrderCart = false
    
    var body: some View {
        VStack{
            List{
                ForEach(menuOverview.menuCategory, id:\.id){ category in
                    Button(action: {
                        self.menuOverview.category = category
                        self.menuOverview.getMenuItems(with: category)
                    }, label: {
                        Text(category.name)
                            .bold()
                            .foregroundColor(Color(UIColor.label))
                    })
                }
            }
            .listStyle(InsetGroupedListStyle())
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
        }
        .sheet(isPresented: $menuOverview.presentMenu){
            MenuItemView(menuOverView: menuOverview, restaurantOrder: restaurantOrder, dismissMenu: $menuOverview.presentMenu, totalPrice: restaurantOrder.totalPrice)
        }
        .alert(item: $alertitem){ alert in
            Alert(title: alert.title, message: alert.message, dismissButton: alert.dismissButton)
        }
    }
}

struct MenuItemView: View {
    @ObservedObject var menuOverView: MenuOverViewWork
    @ObservedObject var restaurantOrder: RestaurantOrderWork
    @Binding var dismissMenu: Bool
    var totalPrice: Double
    
    var body: some View{
        VStack{
            HStack{
                HStack{
                    Image(systemName: "cart")
                        .font(.custom("SFSymbols", size: 20))
                        .foregroundColor(.blue)
                    
                    Text("\(totalPrice, specifier: "%.2f")EUR")
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
                    ForEach(menuOverView.menuItems, id: \.id){ item in
                        MenuItemCell(restaurantOrder: restaurantOrder, menuOverview: menuOverView, menuItem: item)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
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
                    Image(systemName: "minus.rectangle.fill")
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
