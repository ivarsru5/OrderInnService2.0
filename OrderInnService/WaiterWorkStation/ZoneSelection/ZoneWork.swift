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
    @Published var loadingQuery = true
    @Published var goToTableView = false
    let databse = Firestore.firestore()
    
    @Published var selectedZone: Zones?{
        didSet{
            self.goToTableView.toggle()
        }
    }
    
    func getZones(){
        databse.collection("Restaurants").document(UserDefaults.standard.wiaterQrStringKey).collection("Zone").getDocuments { snapshot, error in
            
            guard let snapshotDocument = snapshot?.documents else{
                print("There is no zones")
                return
            }
            self.zones = snapshotDocument.compactMap { zoneSnapshot -> Zones? in
                guard let collectdeZone = Zones(snapshot: zoneSnapshot) else{
                    //TODO: display alert
                    return nil
                }
                return collectdeZone
            }
            self.loadingQuery = false
            
        }
    }
}
