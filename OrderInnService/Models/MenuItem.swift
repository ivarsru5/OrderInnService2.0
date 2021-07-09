//
//  MenuItem.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Foundation
import FirebaseFirestore

struct MenuItem: Identifiable, Hashable{
    var id = UUID().uuidString
    var name: String
    var price: Double
    var available: Bool
    var destination: String
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let name = data["name"] as? String else{
            return nil
        }
        self.name = name
        
        guard let price = data["price"] as? Double else{
            return nil
        }
        self.price = price
        
        guard let destination = data["destination"] as? String else{
            return nil
        }
        self.destination = destination
        
        guard let available = data["available"] as? Bool else{
            return nil
        }
        self.available = available
    }
}
