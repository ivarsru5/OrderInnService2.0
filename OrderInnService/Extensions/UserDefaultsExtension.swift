//
//  UserDefaultsExtension.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

extension UserDefaults{
    var startScreen: Bool{
        get{
            return (UserDefaults.standard.value(forKey: "qr_scanner") as? Bool ?? false)
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "qr_scanner")
        }
    }
    
    var wiaterQrStringKey: String{
        get{
            return(UserDefaults.standard.value(forKey: "wiater_Qr_String_Key") as? String ?? "")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "wiater_Qr_String_Key")
        }
    }
    
    var kitchenQrStringKey: String{
        get{
            return(UserDefaults.standard.value(forKey: "kitchen_Qr_String_Key") as? String ?? "")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "kitchen_Qr_String_Key")
        }
    }
    
    var currentUser: String{
        get{
            return (UserDefaults.standard.value(forKey: "current_user") as? String ?? "")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "current_user")
        }
    }
}
