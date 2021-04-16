//
//  RestaurantOverView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import FirebaseFirestore

struct Restaurant: Identifiable{
    let id = UUID()
    let name: String
}

class RestaurantInfo: ObservableObject{
    @ObservedObject var qrCode = QrCodeScannerWork()
    @Published var restaurant: Restaurant?
    
    private var database = Firestore.firestore()
    
    func getRestaurant(){
        database.collection("Restaurants").document(qrCode.qrCode).getDocument { (snapshot, error) in
            <#code#>
        }
    }
}
