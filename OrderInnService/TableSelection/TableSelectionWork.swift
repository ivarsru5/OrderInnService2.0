//
//  TableSelectionWork.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI
import FirebaseFirestore

class TableSelectionWork: ObservableObject{
    @Published var tables = [Table]()
    @Published var selectedTabel: Table?
    let database = Firestore.firestore()
    
    func getTables(with zoneId: String){
        database.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("Tables")
            .whereField("zone", isEqualTo: zoneId)
            .getDocuments() { (snapshot, error) in
                
            guard let snapshotDocuments = snapshot?.documents else{
                print("There is no tables")
                return
            }
            self.tables = snapshotDocuments.compactMap { tableSnapshot -> Table? in
                return Table(snapshot: tableSnapshot)
            }
        }
    }
}
