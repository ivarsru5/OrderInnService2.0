//
//  DebugMenu.swift
//  OrderInnService
//
//  Created by paulsnar on 7/8/21.
//

import SwiftUI
import FirebaseFirestore

struct DebugMenu: View {
    @State var userDefaultsDumped = false
    @State var promptToResetUserDefaults = false

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
        let nameSurname = UserDefaults.standard.currentUser.components(separatedBy: " ")
        let name = nameSurname[0], surname = nameSurname[1]

        Firestore.firestore()
            .collection("Restaurants")
            .document(UserDefaults.standard.wiaterQrStringKey)
            .collection("Users")
            // HACK[pn]: We should be storing the user ID instead of their name
            // such that filtering by first and last name isn't necessary and
            // the relevant document can be looked up immediately.
            .whereField("name", isEqualTo: name)
            .whereField("lastName", isEqualTo: surname)
            .getDocuments(completion: { maybeSnapshot, error in
                guard let snapshot = maybeSnapshot else {
                    print("[Debug] Restaurant gone? \(String(describing: error))")
                    actuallyResetUserDefaults()
                }

                // HACK[pn]: See above.
                Firestore.firestore()
                    .collection("Restaurants")
                    .document(UserDefaults.standard.wiaterQrStringKey)
                    .collection("Users")
                    .document(snapshot.documents.first!.documentID)
                    .updateData(["isActive": true], completion: { maybeError in
                        if let error = maybeError {
                            print("[Debug] Failed to update current user: \(String(describing: error))")
                        }
                        actuallyResetUserDefaults()
                    })
            })
    }
    func actuallyResetUserDefaults() -> Never {
        print("=== Resetting user defaults. The app will crash afterwards.")
        UserDefaults.deleteAllValues()
        exit(0)
    }

    var body: some View {
        List {
            Button("Dump User Defaults to Console",
                   action: self.dumpUserDefaultsToConsole)
            Button("Reset App Data",
                   action: { promptToResetUserDefaults = true })
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
}

#if DEBUG
struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
