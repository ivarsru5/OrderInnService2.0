//
//  AuthManager.swift
//  OrderInnService
//
//  Created by paulsnar on 7/9/21.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    enum AuthState {
        case loading
        case unauthenticated
        case authenticatedWaiterUnknownID(restaurantID: Restaurant.ID)
        case authenticatedWaiter(restaurantID: Restaurant.ID, employeeID: Restaurant.Employee.ID)
        case authenticatedKitchen(restaurantID: Restaurant.ID, kitchen: String)
    }

    private var _initialised = false
    @Published private(set) var authState: AuthState {
        didSet {
            if case .loading = oldValue {
                _initialised = true
            } else if _initialised {
                persistAuthState()
            }
        }
    }
    var isAuthenticated: Bool {
        switch authState {
        case .loading, .unauthenticated, .authenticatedWaiterUnknownID(restaurantID: _): return false
        default: return true
        }
    }

    var restaurant: Restaurant!
    var waiter: Restaurant.Employee?
    var kitchen: String? {
        switch authState {
        case .authenticatedKitchen(restaurantID: _, kitchen: let kitchen): return kitchen
        default: return nil
        }
    }

    init() {
        authState = .loading

        let userDefaults = UserDefaults.standard
        if let restaurantID = userDefaults.restaurantID, let userID = userDefaults.userID {
            load(restaurant: restaurantID, user: userID)
        } else if let restaurantID = userDefaults.restaurantID {
            load(kitchenForRestaurant: restaurantID)
        } else {
            authState = .unauthenticated
        }
        _initialised = true
    }

    private var subs = Set<AnyCancellable>()

    private func load(restaurant: Restaurant.ID, user: Restaurant.Employee.ID) {
        var sub: AnyCancellable? = nil
        var sub2: AnyCancellable? = nil

        sub = Restaurant.load(withID: restaurant).sink(receiveCompletion: {
            [unowned self] result in
            if case .failure(let error) = result {
                fatalError("FIXME Failed to load restaurant: \(String(describing: error))")
            }
            if let this = sub {
                self.subs.remove(this)
                sub = nil
            }
        }, receiveValue: {
            [unowned self] restaurant in
            self.restaurant = restaurant

            sub2 = Restaurant.Employee.load(forRestaurantID: restaurant.id, withUserID: user).sink(receiveCompletion: {
                [unowned self] result in
                if case .failure(let error) = result {
                    fatalError("FIXME Failed to load user: \(String(describing: error))")
                }
                if let this = sub2 {
                    self.subs.remove(this)
                    sub2 = nil
                }
            }, receiveValue: { [unowned self] user in
                self.waiter = user
                
                authState = .authenticatedWaiter(restaurantID: restaurant.id, employeeID: user.id)
            })
            sub2!.store(in: &subs)
        })
        sub!.store(in: &subs)
    }

    private func load(kitchenForRestaurant restaurant: Restaurant.ID) {
        var sub: AnyCancellable? = nil

        sub = Restaurant.load(withID: restaurant).sink(receiveCompletion: {
            [unowned self] result in
            if case .failure(let error) = result {
                fatalError("FIXME Failed to load restaurant: \(String(describing: error))")
            }
            if let this = sub {
                self.subs.remove(this)
                sub = nil
            }
        }, receiveValue: {
            [unowned self] restaurant in
            self.restaurant = restaurant

            // TODO[pn 2021-07-09]: If the kitchen parameter gets used, it needs
            // to be loaded from UserDefaults over here instead of this empty
            // string.
            authState = .authenticatedKitchen(restaurantID: restaurant.id, kitchen: "")
        })
        sub!.store(in: &subs)
    }

    func resetAuthState() {
        authState = .unauthenticated
    }

    func logIn(using qrCode: LoginQRCode) -> Future<AuthState, Error> {
        return Future() { [unowned self] resolve in
            var sub: AnyCancellable? = nil
            sub = Restaurant.load(withID: qrCode.restaurantID).sink(receiveCompletion: {
                [unowned self] result in
                if case .failure(let error) = result {
                    resolve(.failure(error))
                }

                if let this = sub {
                    subs.remove(this)
                    sub = nil
                }
            }, receiveValue: { [unowned self] restaurant in
                self.restaurant = restaurant
                switch qrCode {
                case .waiter(_):
                    self.authState = .authenticatedWaiterUnknownID(restaurantID: restaurant.id)
                case .kitchen(_, let kitchen):
                    self.authState = .authenticatedKitchen(restaurantID: restaurant.id, kitchen: kitchen)
                }
                persistAuthState()
                resolve(.success(self.authState))
            })
            sub!.store(in: &subs)
        }
    }

    func finishWaiterLogin(withUser user: Restaurant.Employee) -> Future<Void, Error> {
        guard case .authenticatedWaiterUnknownID(restaurantID: let restaurantID) = self.authState else {
            fatalError("AuthManager.finishWaiterLogin called with improper starting state")
        }
        precondition(restaurantID == user.restaurantID)

        // TODO[pn 2021-07-09]: "active"/"inactive" is pretty inaccurate
        // terminology. Instead this should be called "locked" or something like
        // that.
        // TODO[pn 2021-07-09]: Is there a strategy for marking users as
        // available to use afterwards?
        return Future() { [unowned self] resolve in
            user.firebaseReference.updateData(["isActive": false], completion: {
                [unowned self] maybeError in
                guard maybeError == nil else {
                    resolve(.failure(maybeError!))
                    return
                }

                self.waiter = user
                self.authState = .authenticatedWaiter(restaurantID: restaurantID, employeeID: user.id)
                persistAuthState()
                resolve(.success(()))
            })
        }
    }

    private func persistAuthState() {
        let restaurantID: Restaurant.ID?
        let userID: Restaurant.Employee.ID?
        switch authState {
        case .loading:
            fatalError("BUG Tried to persist loading (i.e, undefined) auth state to UserDefaults")
        case .unauthenticated, .authenticatedWaiterUnknownID(restaurantID: _):
            restaurantID = nil
            userID = nil
        case .authenticatedWaiter(restaurantID: let _restaurantID, employeeID: let _userID):
            restaurantID = _restaurantID
            userID = _userID

            // HACK[pn]: Please see UserDefaultsExtension. 
            UserDefaults.standard.currentUser = "\(waiter!.name) \(waiter!.lastName)"
        case .authenticatedKitchen(restaurantID: let _restaurantID, kitchen: _):
            restaurantID = _restaurantID
            userID = nil
        }
        UserDefaults.standard.restaurantID = restaurantID
        UserDefaults.standard.userID = userID
    }
}
