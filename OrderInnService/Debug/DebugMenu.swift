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
    @EnvironmentObject var authManager: AuthManager
    @State var userDefaultsDumped = false
    @State var promptToResetUserDefaults = false

    func switchActiveUserToWaiter() {
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

    func switchActiveUserToAdmin() {
        switch authManager.authState {
        case .authenticatedAdmin(restaurantID: _, admin: _): return
        default: break
        }

        let qr = LoginQRCode.admin(restaurantID: authManager.restaurant.id, admin: "")

        var sub: AnyCancellable?
        sub = authManager.logIn(using: qr)
            .sink(receiveCompletion: { _ in
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

    private func logout() -> AnyPublisher<Void, Error> {
        guard let waiter = authManager.waiter else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return waiter.firestoreReference
            .updateData(["isActive": true])
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func clearFirestorePersistence() -> AnyPublisher<Void, Error> {
        var firestore: Firestore?
        firestore = Firestore.firestore()
        return Future<Void, Error>() { resolve in
            firestore!.terminate(completion: { maybeError in
                guard maybeError == nil else {
                    resolve(.failure(maybeError!))
                    return
                }

                firestore!.clearPersistence(completion: { maybeError in
                    guard maybeError == nil else {
                        resolve(.failure(maybeError!))
                        return
                    }

                    if let _ = firestore {
                        // HACK[pn]: We need to keep the Firestore instance
                        // alive longer than the clearPersistence call, since
                        // doing otherwise can apparently cause a deadlock by
                        // the instance attempting to do cleanup on dealloc
                        // exactly during clearPersistence running. I guess
                        // nobody expected that the Firestore instance wouldn't
                        // actually be kept floating around statically and
                        // instead be materialised whenever needed ::shrug::
                    }

                    resolve(.success(()))
                })
            })
        }.eraseToAnyPublisher()
    }

    func resetUserDefaults() {
        // NOTE[pn]: Due to the Firebase model, we need to mark the current user
        // as having effectively logged out, hence we do that here such that
        // it's possible to log in afterwards.

        var sub: AnyCancellable?
        sub = logout()
            .flatMap { _ in self.clearFirestorePersistence() }
            .catch { error -> Empty<Void, Never> in
                print("[Debug] Failed to reset app data: \(String(describing: error))")
                return Empty()
            }
            .sink {
                if let _ = sub {
                    sub = nil
                }

                print("=== [Debug] Resetting user defaults and quitting.")
                UserDefaults.deleteAllValues()
                exit(0)
            }
    }

    var isCurrentlyKitchen: Bool {
        switch authManager.authState {
        case .authenticatedKitchen(_, _): return true
        default: return false
        }
    }
    var isCurrentlyAdmin: Bool {
        switch authManager.authState {
        case .authenticatedAdmin(_, _): return true
        default: return false
        }
    }

    var body: some View {
        List {
            Section(header: Text("Active User")) {
                Button(authManager.waiter == nil ? "Switch to Waiter" : "Switch to Different Waiter",
                       action: self.switchActiveUserToWaiter)
                Button("Switch to Kitchen",
                       action: self.switchActiveUserToKitchen)
                    .disabled(isCurrentlyKitchen)
                Button("Switch to Admin",
                       action: self.switchActiveUserToAdmin)
                    .disabled(isCurrentlyAdmin)
            }
            Section(header: Text("App Data")) {
                Button("Dump User Defaults to Console",
                       action: self.dumpUserDefaultsToConsole)

                if #available(iOS 15.0, *) {
                    Button("Reset App Data", role: .destructive,
                           action: { promptToResetUserDefaults = true })
                } else {
                    Button(action: {
                        promptToResetUserDefaults = true
                    }, label: {
                        Text("Reset App Data").foregroundColor(.red)
                    })
                }
            }
        }
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
        return withTabItem
    }

    static var withTabItem: some View {
        DebugMenu()
        .tabItem {
            Image(systemName: "wrench.and.screwdriver")
            Text("Debug")
        }
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
        DebugMenu().colorScheme(.dark)
    }
}
#endif
