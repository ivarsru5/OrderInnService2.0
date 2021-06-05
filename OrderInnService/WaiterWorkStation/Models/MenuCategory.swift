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
    var menuItems: [MenuItem]
    var isExpanded = false
    
    init?(snapshot: QueryDocumentSnapshot, menuItems: [MenuItem]){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let name = data["name"] as? String else {
            return nil
        }
        self.name = name
        self.menuItems = menuItems
    }
}
