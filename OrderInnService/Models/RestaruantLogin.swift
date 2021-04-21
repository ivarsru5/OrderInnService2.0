//
//  RestaruantLogin.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 16/04/2021.
//

import SwiftUI
import FirebaseFirestore

struct Restaurant: Identifiable{
    var id = UUID().uuidString
    var name: String = ""
    var subscriptionPaid = true
    
    struct RestaurantEmploye: Identifiable{
        var id = UUID().uuidString
        let name: String
        let lastName: String
        let isActive: Bool
        
        init?(snapshot: QueryDocumentSnapshot){
            let data = snapshot.data()
            self.id = snapshot.documentID
            
            guard let name = data["name"] as? String else{
                return nil
            }
            self.name = name
            
            guard let lastName = data["lastName"] as? String else{
                return nil
            }
            self.lastName = lastName
            
            guard let isActive = data["isActive"] as? Bool else{
                return nil
            }
            self.isActive = isActive
        }
    }
}
