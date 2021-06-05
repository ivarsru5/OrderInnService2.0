//
//  MenuCategory.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Foundation
import FirebaseFirestore

struct MenuCategory: Identifiable, Hashable{
    var id = UUID().uuidString
    var name: String
    var type: String
    var menuItems: [MenuItem]
    var isExpanded = false
    
    init?(snapshot: QueryDocumentSnapshot, menuItems: [MenuItem]){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let type = data["type"] as? String else{
            return nil
        }
        self.type = type
        
        guard let name = data["name"] as? String else {
            return nil
        }
        self.name = name
        self.menuItems = menuItems
    }
}

struct MenuDrinks: Identifiable, Hashable{
    let id = UUID().uuidString
    var name: String
    var isExpanded = false
    var drinks: [MenuItem]
}
