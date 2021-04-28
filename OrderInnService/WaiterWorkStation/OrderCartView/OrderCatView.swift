//
//  OrderCatView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import SwiftUI

struct OrderCatView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var restaurantOrder: RestaurantOrderWork
    @Binding var dimsissCart: Bool
    
    var body: some View {
        if !restaurantOrder.sendingQuery{
            VStack{
                List{
                    Section(header: Text("Selected items's")){
                        ForEach(restaurantOrder.restaurantOrder.menuItems, id: \.id){ item in
                            HStack{
                                HStack{
                                    Image(systemName: "circle.fill")
                                        .font(.custom("SF Symbols", size: 10))
                                        .foregroundColor(Color(UIColor.label))
                                    
                                    Text(item.name)
                                        .bold()
                                        .foregroundColor(Color(UIColor.label))
                                }
                                
                                Spacer()
                                
                                HStack{
                                    Text("\(item.price, specifier: "%.2f")EUR")
                                        .italic()
                                        .foregroundColor(Color(UIColor.label))
                                    
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
                    
                    ForEach(restaurantOrder.courses, id: \.index){ course in
                        Section(header: Text("Course \(course.index)")){
                            ForEach(course.menuItems, id:\.id){ item in
                                
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
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Order")
                .navigationBarItems(trailing: HStack{
                    Button(action: {
                        dimsissCart.toggle()
                    }, label: {
                        Text("Return")
                            .foregroundColor(.red)
                    })
                })
                
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
                    restaurantOrder.sendOrder(presentationMode: presentationMode)
                    //                withAnimation(.easeOut(duration: 0.5)){
                    //                    _ = restaurantOrder.groupCourse(fromItems: restaurantOrder.restaurantOrder.menuItems)
                    //                }
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
        }else{
            Spinner()
        }
    }
}
