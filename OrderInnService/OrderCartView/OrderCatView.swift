//
//  OrderCatView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import SwiftUI

struct OrderCatView: View {
    @EnvironmentObject var restaurantOrder: RestaurantOrderWork
    
    var body: some View {
        VStack{
            List{
                Section(header: Text("Client order")){
                    ForEach(restaurantOrder.restaurantOrder.menuItems, id: \.id){ item in
                        HStack{
                            HStack{
                                Image(systemName: "circle.fill")
                                    .font(.custom("SF Symbols", size: 10))
                                    .foregroundColor(Color(UIColor.label))
                                
                                Text(item.name)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            HStack{
                                Text("\(item.price, specifier: "%.2f")EUR")
                                    .italic()
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.5)){
                                        restaurantOrder.removeFromOrder(item)
                                    }
                                }, label: {
                                    Image(systemName: "xmark.circle")
                                        .font(.custom("SF Symbols", size: 20))
                                        .foregroundColor(.blue)
                                })
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Order")
            
            HStack{
                Text("Total Order Amount")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Spacer()
                
                Text("EUR\(restaurantOrder.totalPrice, specifier: "%.2f")")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
            .padding()
            
            Button(action: {
                
            }, label: {
                Text("Send Order")
                    .bold()
                    .frame(width: 250, height: 50, alignment: .center)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .background(Color(UIColor.label))
                    .cornerRadius(15)
            })
            .padding()
        }
    }
}
