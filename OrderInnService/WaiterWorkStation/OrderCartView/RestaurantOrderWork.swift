//
//  RestaurantOrderWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 23/04/2021.
//

import SwiftUI
import FirebaseFirestore

class RestaurantOrderWork: ObservableObject{
    @Published var restaurantOrder = RestaurantOrder()
    @Published var courses = [RestaurantOrder.Course]()
    @Published var totalPrice = 0.00
    @Published var sendingQuery = false
    private var databse = Firestore.firestore()
    
    func updatePrice(forItem: MenuItem){
        self.totalPrice = restaurantOrder.menuItems.reduce(0) { $0 + $1.price }
    }
    
    func addToOrder(_ menuItem: MenuItem){
        restaurantOrder.menuItems.append(menuItem)
        updatePrice(forItem: menuItem)
    }
    
    func removeFromOrder(_ menuItem: MenuItem){
        if let index = restaurantOrder.menuItems.firstIndex(where: {$0.id == menuItem.id}){
            restaurantOrder.menuItems.remove(at: index)
            updatePrice(forItem: menuItem)
        }
    }
    
    func getItemCount(forItem: MenuItem) -> Int{
        return restaurantOrder.menuItems.filter { $0 == forItem }.count
    }
    
    func sendOrder(presentationMode: Binding<PresentationMode>){
        sendingQuery = true
        
        let itemName = restaurantOrder.menuItems.map{ item -> String in
            return "\(item.name)" + "/\(item.price)"
        }
        
        let documentData: [String: Any] = [
            "orderItems" : itemName,
            "placedBy" : restaurantOrder.placedBy,
            "forTable": restaurantOrder.forTable,
            "toatlOrderPrice": totalPrice,
            "orderComplete": restaurantOrder.orderCompleted,
            "orderClosed" : restaurantOrder.orderClosed
        ]
        
        databse.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("Order")
            .addDocument(data: documentData) { error in
                if let err = error{
                    print("Document did not create \(err)")
                }else{
                    print("Document created!")
                    self.restaurantOrder.menuItems.removeAll()
                    presentationMode.wrappedValue.dismiss()
                    self.totalPrice = 0.00
                    self.sendingQuery = false
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
