//
//  ZoneWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

class ZoneWork: ObservableObject{
    @Published var zones = [Zone]()
    @Published var loadingQuery = true
    @Published var goToTableView = false
    let databse = Firestore.firestore()
    
    @Published var selectedZone: Zone?{
        didSet{
            self.goToTableView.toggle()
        }
    }
    
    func getZones(for restaurant: Restaurant){
        restaurant.firestoreReference.untyped.collection("Zone").getDocuments { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no zones")
                return
            }
            self.zones = snapshotDocument.compactMap { zoneSnapshot -> Zone? in
                guard let collectdeZone = Zone(snapshot: zoneSnapshot) else{
                    //TODO: display alert
                    return nil
                }
                return collectdeZone
            }
            self.loadingQuery = false
            
        }
    }
}
