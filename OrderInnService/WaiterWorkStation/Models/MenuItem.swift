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
    }
}