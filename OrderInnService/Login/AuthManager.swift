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
        willSet {
            // HACK[pn]: Since SwiftUI updates views in a weird order that
            // can cause conditionals not to be re-rendered before their children
            // are, and since switching authState while one of the children views
            // is already rendered can cause crashes due to accessing nilable data,
            // we need to propagate this cached value separately and, more importantly,
            // *not remove it* if authState is switched from kitchen to waiter.
            if case .authenticatedKitchen(restaurantID: _, kitchen: let kitchen) = newValue {
                self.kitchen = kitchen
            }
        }
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
    private(set) var kitchen: String?

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
        var sub: AnyCancellable?
        sub = Restaurant.load(withID: restaurant)
            .mapError { error in
                fatalError("FIXME Failed to load restaurant: \(String(describing: error))")
            }
            .flatMap { [unowned self] restaurant -> AnyPublisher<Restaurant.Employee, Error> in
                self.restaurant = restaurant
                return Restaurant.Employee.load(forRestaurantID: restaurant.id, withUserID: user)
            }
            .mapError { error in
                fatalError("FIXME Failed to load user: \(String(describing: error))")
            }
            .sink { [unowned self] user in
                self.waiter = user
                authState = .authenticatedWaiter(restaurantID: self.restaurant.id, employeeID: user.id)
                if let _ = sub {
                    sub = nil
                }
            }
    }

    private func load(kitchenForRestaurant restaurant: Restaurant.ID) {
        var sub: AnyCancellable?
        sub = Restaurant.load(withID: restaurant)
            .mapError { error in
                fatalError("FIXME Failed to load restaurant: \(String(describing: error))")
            }
            .sink { [unowned self] restaurant in
                self.restaurant = restaurant
                authState = .authenticatedKitchen(restaurantID: self.restaurant.id, kitchen: "")
                if let _ = sub {
                    sub = nil
                }
            }
    }

    func resetAuthState() {
        if case .authenticatedWaiter(restaurantID: _, employeeID: _) = authState {
            var sub: AnyCancellable?
            sub = logoutWaiter().sink(receiveCompletion: {
                [unowned self] result in
                if case .failure(let error) = result {
                    print("Failed to log out: \(String(describing: error))")
                }
                authState = .unauthenticated
                if let _ = sub {
                    sub = nil
                }
            }, receiveValue: { })
        } else {
            authState = .unauthenticated
        }
    }

    func testAsyncReturnBool() async -> Bool {
        return true
    }

    func logIn(using qrCode: LoginQRCode) -> AnyPublisher<AuthState, Error> {
        var logoutPublisher: AnyPublisher<Void, Error>

        if case .authenticatedWaiter(restaurantID: _, employeeID: _) = self.authState {
            logoutPublisher = logoutWaiter().eraseToAnyPublisher()
        } else {
            logoutPublisher = Just(())
                .mapError { _ in DummyError.unexpectedError }
                .eraseToAnyPublisher()
        }

        return logoutPublisher
            .flatMap {
                Restaurant.load(withID: qrCode.restaurantID)
            }
            .map { [unowned self] restaurant -> AuthState in
                self.restaurant = restaurant

                switch qrCode {
                case .waiter(_):
                    self.authState = .authenticatedWaiterUnknownID(restaurantID: restaurant.id)
                case .kitchen(_, let kitchen):
                    self.authState = .authenticatedKitchen(restaurantID: restaurant.id, kitchen: kitchen)
                }

                return self.authState
            }
            .eraseToAnyPublisher()
    }

    func logoutWaiter() -> AnyPublisher<Void, Error> {
        guard case .authenticatedWaiter(restaurantID: _, employeeID: _) = authState else {
            fatalError("AuthManager.logoutWaiter called with improper starting state")
        }

        return waiter!.firebaseReference
            .updateDataFuture(["isActive": true])
            .map { [unowned self] in
                self.waiter = nil
            }
            .eraseToAnyPublisher()
    }

    func finishWaiterLogin(withUser user: Restaurant.Employee) -> AnyPublisher<Void, Error> {
        guard case .authenticatedWaiterUnknownID(restaurantID: let restaurantID) = self.authState else {
            fatalError("AuthManager.finishWaiterLogin called with improper starting state")
        }
        precondition(restaurantID == user.restaurantID)

        // TODO[pn 2021-07-09]: "active"/"inactive" is pretty inaccurate
        // terminology. Instead this should be called "locked" or something like
        // that.
        // TODO[pn 2021-07-09]: Is there a strategy for marking users as
        // available to use afterwards?
        return user.firebaseReference
            .updateDataFuture(["isActive": false])
            .map { [unowned self] in
                self.waiter = user
                self.authState = .authenticatedWaiter(restaurantID: restaurantID, employeeID: user.id)
            }
            .eraseToAnyPublisher()
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
