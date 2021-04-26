//
//  MenuView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI
import Combine

struct MenuView: View {
    @EnvironmentObject var restaurantOrder: RestaurantOrderWork
    @StateObject var menuOverview = MenuOverViewWork()
    @ObservedObject var table: TableSelectionWork
    @State var alertitem: AlertItem?
    @State var showOrder = false
    
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
                    showOrder.toggle()
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
            })
            
           NavigationLink(destination: OrderCatView(), isActive: $showOrder){ EmptyView() }
        }
        .navigationTitle("\(table.selectedTabel!.table)")
        .onAppear{
            menuOverview.getMenuCategory()
        }
        .sheet(isPresented: $menuOverview.presentMenu){
            MenuItemView(menuOverView: menuOverview, dismissMenu: $menuOverview.presentMenu, totalPrice: restaurantOrder.totalPrice)
        }
        .alert(item: $alertitem){ alert in
            Alert(title: alert.title, message: alert.message, dismissButton: alert.dismissButton)
        }
    }
}

struct MenuItemView: View {
    @ObservedObject var menuOverView: MenuOverViewWork
    @Binding var dismissMenu: Bool
    //@Binding var showOrder: Bool
    var totalPrice: Double
    
    var body: some View{
        VStack{
            HStack{
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
            }
            .padding()
            
            VStack{
                Text(menuOverView.category!.name)
                    .bold()
                    .foregroundColor(Color(UIColor.label))
                    .font(.headline)
                
                List{
                    ForEach(menuOverView.menuItems, id: \.id){ item in
                        MenuItemCell(menuOverview: menuOverView, menuItem: item)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
//        .fullScreenCover(isPresented: $showOrder){
//            NavigationView{
//                OrderCatView()
//            }
//        }
    }
}

struct MenuItemCell: View{
    @EnvironmentObject var restaurantOrder: RestaurantOrderWork
    @ObservedObject var menuOverview: MenuOverViewWork
    var menuItem: MenuItem
    
    var itemAmount: Int{
            restaurantOrder.getItemCount(from: restaurantOrder.restaurantOrder.menuItems, forItem: menuItem)
    }
    
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
                }, label: {
                        Image(systemName: "plus.rectangle.fill")
                            .font(.custom("SF Symbols", size: 30))
                            .foregroundColor(Color.white)
                    })
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.all, 5)
    }
}
//struct NavigatinButton: View{
//    @EnvironmentObject var restaurantOrder: RestaurantOrderWork
//    @State var presntOrderCart = false
//
//    var body: some View{
//        ZStack{
//            Button(action: {
//                presntOrderCart.toggle()
//            }, label: {
//                Image(systemName: "cart")
//                    .font(.custom("SF Symbols", size: 20))
//                    .foregroundColor(.blue)
//
//                Text("\(restaurantOrder.totalPrice, specifier: "%.2f")")
//                    .italic()
//                    .foregroundColor(.blue)
//            })
//            NavigationLink(destination: OrderCatView(), isActive: $presntOrderCart, label: { EmptyView() })
//        }
//        .frame(height: 96, alignment: .trailing)
//    }
//}
