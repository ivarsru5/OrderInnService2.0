//
//  UserDefaultsExtension.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import Foundation
import FirebaseFirestore

extension UserDefaults {
    fileprivate static let o6nPrefix = "group.orderinn.ios.service2"

    fileprivate enum Keys: String {
        /// The document ID for the restaurant the user is currently logged into.
        case restaurantID = "restaurant_id"

        /// The user ID who is currently logged into the app.
        ///
        /// If the stored value is `nil` or the value is absent while `restaurantID` isn't,
        /// the logged-in user is the kitchen.
        ///
        ///     TODO[pn 2021-07-09]: If kitchens need to be identified more
        ///     granularly, this needs to be reworked.
        case userID = "user_id"

        /// True if the currently logged-in user is using an admin code and as such the admin interface
        /// should be presented.
        case isAdmin = "is_admin"

        var key: String {
            return "\(UserDefaults.o6nPrefix).\(self.rawValue)"
        }

        static let allKeys = [
            restaurantID,
            userID,
        ]
    }

    var restaurantID: String? {
        get {
            return self.string(forKey: Keys.restaurantID.key)
        }
        set {
            if newValue != nil {
                self.set(newValue!, forKey: Keys.restaurantID.key)
            } else {
                self.removeObject(forKey: Keys.restaurantID.key)
            }
        }
    }
    var userID: String? {
        get {
            return self.string(forKey: Keys.userID.key)
        }
        set {
            if newValue != nil {
                self.set(newValue!, forKey: Keys.userID.key)
            } else {
                self.removeObject(forKey: Keys.userID.key)
            }
        }
    }
    var isAdmin: Bool? {
        get {
            return self.bool(forKey: Keys.isAdmin.key)
        }
        set {
            self.set(newValue, forKey: Keys.isAdmin.key)
        }
    }


    static func deleteAllValues() {
        Keys.allKeys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key.key)
        }
    }
}
