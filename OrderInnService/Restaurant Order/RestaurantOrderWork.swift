//
//  RestaurantOrderWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import Foundation

class RestaurantOrderWork: ObservableObject{
    @Published var restaurantOrder = RestaurantOrder()
    
    @Published var itemAmount: Int = 0{
        didSet{
            let itemAmountState = restaurantOrder?.menuItems.filter() { $0.id == $0.id }
            self.itemAmount = itemAmountState!.count
        }
    }
    
    var totalPrice: Double{
        restaurantOrder?.menuItems.reduce(0) { $0 + $1.price } ?? 0.00
    }
    
    func addToOrder(_ menuItem: MenuItem){
        restaurantOrder?.menuItems.append(menuItem)
    }
    
    func removeFromOrder(_ menuItem: MenuItem){
        if let index = restaurantOrder?.menuItems.firstIndex(where: {$0.id == menuItem.id}){
            restaurantOrder?.menuItems.remove(at: index)
        }
        if (restaurantOrder?.menuItems.count)! == 0{
            self.restaurantOrder = nil
        }
    }
}
