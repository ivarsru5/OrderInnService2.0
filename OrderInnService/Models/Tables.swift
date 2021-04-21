//
//  Tables.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import Foundation
import FirebaseFirestore

struct Table: Identifiable{
    var id = UUID().uuidString
    var zone: String
    var table: String
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let zone = data["zone"] as? String else{
            return nil
        }
        self.zone = zone
        
        guard let table = data["table"] as? String else{
            return nil
        }
        self.table = table
    }
}
