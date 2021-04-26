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
    var totalPrice: Double
    
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
    }
}
