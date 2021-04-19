//
//  ZoneWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

class ZoneWork: ObservableObject{
    @Published var zones = [Zones]()
    @Published var selectedZone: Zones?
    
    func getZones(with referance: DocumentReference){
        referance.collection("Zone").getDocuments(source: .cache) { snapshot, error in
            DispatchQueue.main.async {
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no zones")
                    return
                }
                self.zones = snapshotDocument.map { zoneSnapshot -> Zones in
                    let data = zoneSnapshot.data()
                    
                   // let id = zoneSnapshot.documentID
                    let location = data["location"] as? String ?? ""
                    
                    return Zones(location: location)
                }
            }
        }
    }
}
