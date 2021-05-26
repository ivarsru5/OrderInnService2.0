//
//  KitchenOrder.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 22/05/2021.
//

import Foundation
import FirebaseFirestore

struct KitchenOrder: Identifiable {
    var id = UUID().uuidString
    var kitchenItems: [String]
    var barItems: [String]
    var placedBy: String
    var orderCompleted: Bool
    var orderClosed: Bool
    var totalPrice: Double
    var forTable: String
    var forZone: String
    var withExtras: [ActiveExtraOrder]
    
    init?(snapshot: QueryDocumentSnapshot, extraOrders: [ActiveExtraOrder]){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let kitchenItems = data["kitchenItems"] as? [String] else{
            return nil
        }
        self.kitchenItems = kitchenItems
        
        guard let barItems = data["barItems"] as? [String] else{
            return nil
        }
        self.barItems = barItems
        
        guard let placedBy = data["placedBy"] as? String else{
            return nil
        }
        self.placedBy = placedBy
        
        guard let orderCompleted = data["orderComplete"] as? Bool else{
            return nil
        }
        self.orderCompleted = orderCompleted
        
        guard let totalPrice = data["toatlOrderPrice"] as? Double else{
            return nil
        }
        self.totalPrice = totalPrice
        
        guard let forTable = data["forTable"] as? String else{
            return nil
        }
        self.forTable = forTable
        
        guard let orderClosed = data["orderClosed"] as? Bool else{
            return nil
        }
        self.orderClosed = orderClosed
        
        guard let forZone = data["inZone"] as? String else{
            return nil
        }
        self.forZone = forZone
        
        self.withExtras = extraOrders
    }
}