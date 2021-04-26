//
//  RestaurantOrderWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import Foundation
import FirebaseFirestore

class RestaurantOrderWork: ObservableObject{
    @Published var restaurantOrder = RestaurantOrder()
    @Published var courses = [RestaurantOrder.Course]()
    private var databse = Firestore.firestore()
    
    var totalPrice: Double{
        if !restaurantOrder.menuItems.isEmpty{
            return restaurantOrder.menuItems.reduce(0) { $0 + $1.price }
        }else{
            return 0.00
        }
    }
    
    func addToOrder(_ menuItem: MenuItem){
        restaurantOrder.menuItems.append(menuItem)
    }
    
    func removeFromOrder(_ menuItem: MenuItem){
        if let index = restaurantOrder.menuItems.firstIndex(where: {$0.id == menuItem.id}){
            restaurantOrder.menuItems.remove(at: index)
        }
    }
    
    func getItemCount(from items: [MenuItem], forItem: MenuItem) -> Int{
        return items.filter { $0 == forItem }.count
    }
    
    func sendOrder(with order: RestaurantOrder){        
        let itemName = order.menuItems.map{ item -> String in
            return item.name
        }
        
        let documentData: [String: Any] = [
            "placedBy" : order.placedBy,
            "orderItems" : itemName
        ]
        
        databse.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("Order")
            .document(order.id)
            .setData(documentData, merge: true) { error in
                if let err = error{
                    print("Document did not create \(err)")
                }else{
                    print("Document created!")
            }
        }
    }
    
    
    func groupCourse(fromItems items: [MenuItem]) -> RestaurantOrder.Course{
        
        let menuItems = items.map{ item -> MenuItem in
            let index = self.restaurantOrder.menuItems.firstIndex(where: { $0.id == item.id })!
            let menuItem = self.restaurantOrder.menuItems[index]
            self.restaurantOrder.menuItems.remove(at: index)
            return menuItem
        }
        
        let course = RestaurantOrder.Course(index: self.courses.count + 1, menuItems: menuItems)
        self.courses.append(course)
        return course
    }
}
