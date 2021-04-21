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
    @Published var loadingQuery = false
    @Published var goToMenu = false
    let database = Firestore.firestore()
    
    @Published var selectedTabel: Table?{
        didSet{
            goToMenu.toggle()
        }
    }
    
    func getTables(with zoneId: Zones){
        database.collection("Restaurants")
            .document(UserDefaults.standard.qrStringKey)
            .collection("Zone")
            .document(zoneId.id)
            .collection("Tables")
            .getDocuments { snapshot, error in
                guard let snapshotDocument = snapshot?.documents else{
                    print("There is no tables")
                    return
                }
                let collectedTables = snapshotDocument.compactMap{ tableSnapshot -> Table? in
                    return Table(snapshot: tableSnapshot)
            }
                self.tables = collectedTables.sorted{ $0.table < $1.table }
                self.loadingQuery = false
        }
    }
}
