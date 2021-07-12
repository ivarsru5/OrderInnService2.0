//
//  DebugMenu.swift
//  OrderInnService
//
//  Created by paulsnar on 7/8/21.
//

import SwiftUI
import Combine
import FirebaseFirestore

#if DEBUG
struct DebugMenu: View {
    class Model {
        var subs = Set<AnyCancellable>()
    }

    @EnvironmentObject var authManager: AuthManager
    @State var userDefaultsDumped = false
    @State var promptToResetUserDefaults = false

    func switchActiveUserToWaiter() {
        switch authManager.authState {
        case .authenticatedWaiter(restaurantID: _, employeeID: _): return
        default: break
        }

        let qr = LoginQRCode.waiter(restaurantID: authManager.restaurant.id)
        var sub: AnyCancellable?
        sub = authManager.logIn(using: qr).sink(receiveCompletion: {
            _ in
            if let _ = sub {
                sub = nil
            }
        }, receiveValue: { _ in })
    }

    func switchActiveUserToKitchen() {
        switch authManager.authState {
        case .authenticatedKitchen(restaurantID: _, kitchen: _): return
        default: break
        }

        let qr = LoginQRCode.kitchen(restaurantID: authManager.restaurant.id, kitchen: "")

        var sub: AnyCancellable?
        sub = authManager.logIn(using: qr).sink(receiveCompletion: {
            _ in
            if let _ = sub {
                sub = nil
            }
        }, receiveValue: { _ in })
    }

    func dumpUserDefaultsToConsole() {
        print("=== Begin user defaults dump.")
        UserDefaults.standard.dictionaryRepresentation().forEach {
            key, value in
            print("[UserDefaults] \(key): \(String(describing: value))")
        }
        print("=== End user defaults dump.")

        userDefaultsDumped = true
    }

    func resetUserDefaults() {
        // NOTE[pn]: Due to the Firebase model, we need to mark the current user
        // as having effectively logged out, hence we do that here such that
        // it's possible to log in afterwards. Actual UserDefaults clearing goes
        // on in actuallyResetUserDefaults.
        if let waiter = authManager.waiter {
            waiter.firebaseReference.updateData(["isActive": true], completion: { maybeError in
                if let error = maybeError {
                    print("[Debug] Failed to update current user: \(String(describing: error))")
                }
                actuallyResetUserDefaults()
            })
        } else {
            // Technically unreachable since this screen is attached only to
            // the service workflow, but regardless.
            actuallyResetUserDefaults()
        }
    }
    func actuallyResetUserDefaults() -> Never {
        print("=== Resetting user defaults. The app will crash afterwards.")
        UserDefaults.deleteAllValues()
        exit(0)
    }

    var body: some View {
        List {
            Section(header: Text("Active User")) {
                Button("Switch to Waiter",
                       action: self.switchActiveUserToWaiter)
                Button("Switch to Kitchen",
                       action: self.switchActiveUserToKitchen)
            }
            Section(header: Text("App Data")) {
                Button("Dump User Defaults to Console",
                       action: self.dumpUserDefaultsToConsole)
                Button("Reset App Data",
                       action: { promptToResetUserDefaults = true })
            }
        }
        .navigationTitle("Debug Actions")
        .alert(isPresented: $userDefaultsDumped) {
            Alert(title: Text("User Defaults Dumped"),
                  message: Text("Please check the console."),
                  dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $promptToResetUserDefaults) {
            Alert(title: Text("Reset App Data?"),
                  message: Text("This will cause you to be logged out and " +
                                "may cause undesired behaviour."),
                  primaryButton: .destructive(Text("Yes"),
                                              action: self.resetUserDefaults),
                  secondaryButton: .default(Text("No")))
        }
    }

    static var navigationViewWithTabItem: some View {
        NavigationView {
            DebugMenu()
        }
        .tabItem {
            Image(systemName: "wrench.and.screwdriver")
            Text("Debug")
        }
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
