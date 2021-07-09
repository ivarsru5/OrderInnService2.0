//
//  Zones.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

struct Zone: Identifiable {
    var id = UUID().uuidString
    let location: String
    
    init?(snapshot: QueryDocumentSnapshot){
        let data = snapshot.data()
        self.id = snapshot.documentID
        
        guard let location = data["location"] as? String else{
            return nil
        }
        self.location = location
    }
}
