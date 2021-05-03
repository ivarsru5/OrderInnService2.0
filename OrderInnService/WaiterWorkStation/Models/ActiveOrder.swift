//
//  ActiveOrder.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 26/04/2021.
//

import Foundation
import FirebaseFirestore

struct ActiveOrder: Identifiable {
    var id = UUID().uuidString
    var orderItems: [String]
    var placedBy: String
    var orderCompleted: Bool
    var orderClosed: Bool
    var totalPrice: Double
    var forTable: String
    var forZone: String
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let orderItems = data["orderItems"] as? [String] else{
            return nil
        }
        self.orderItems = orderItems
        
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
    }
}

struct ActiveExtraOrder: Identifiable{
    var id = UUID().uuidString
    var extraItems: [String]
    var orderId: String
    var extraOrderPart: Int
    var extraOrderPrice: Double
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let extraitems = data["additionalOrder"] as? [String] else{
            return nil
        }
        self.extraItems = extraitems
        
        guard let orderId = data["forOrder"] as? String else{
            return nil
        }
        self.orderId = orderId
        
        guard let extraOrderPart = data["extraPart"] as? Int else{
            return nil
        }
        self.extraOrderPart = extraOrderPart
        
        guard let extraOrderPrice = data["extraPrice"] as? Double else{
            return nil
        }
        self.extraOrderPrice = extraOrderPrice
    }
}
