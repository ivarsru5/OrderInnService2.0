//
//  UserDefaultsExtension.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

extension UserDefaults{
    fileprivate enum Keys: String {
        case startScreen = "qr_scanner"
        case waiterQrString = "wiater_Qr_String_Key"
        case kitchenQrString = "kitchen_Qr_String_Key"
        case currentUser = "current_user"

        static let allKeys = [
            startScreen,
            waiterQrString,
            kitchenQrString,
            currentUser,
        ]
    }

    var startScreen: Bool{
        get{
            return (UserDefaults.standard.value(forKey: Keys.startScreen.rawValue) as? Bool ?? false)
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: Keys.startScreen.rawValue)
        }
    }
    
    var wiaterQrStringKey: String{
        get{
            return(UserDefaults.standard.value(forKey: Keys.waiterQrString.rawValue) as? String ?? "")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: Keys.waiterQrString.rawValue)
        }
    }
    
    var kitchenQrStringKey: String{
        get{
            return(UserDefaults.standard.value(forKey: Keys.kitchenQrString.rawValue) as? String ?? "")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: Keys.kitchenQrString.rawValue)
        }
    }
    
    var currentUser: String{
        get{
            return (UserDefaults.standard.value(forKey: Keys.currentUser.rawValue) as? String ?? "")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: Keys.currentUser.rawValue)
        }
    }

    static func deleteAllValues() {
        Keys.allKeys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
