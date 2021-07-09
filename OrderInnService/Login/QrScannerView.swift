//
//  ContentView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import Combine

struct QrScannerView: View {
    @EnvironmentObject var authManager: AuthManager
    @State var alertItem: AlertItem?

    var isAuthPendingUserSelection: Bool {
        switch authManager.authState {
        case .authenticatedWaiterUnknownID(restaurantID: _): return true
        default: return false
        }
    }
    var isAuthPendingUserSelectionBinding: Binding<Bool> {
        return .constant(isAuthPendingUserSelection)
    }
    var body: some View {
        ZStack {
            QrCodeScannerView(alertItem: $alertItem)
                .edgesIgnoringSafeArea(.all)
            
            BlurEffectView(effect: UIBlurEffect(style: .dark))
                .inverseMask(Circle().padding())
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Please scan QR code.")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 60)
                
                Spacer()
            }
        }
        .alert(item: $alertItem){ alert in
            Alert(title: alert.title,
                  message: alert.message,
                  dismissButton: alert.dismissButton)
            
        }
        .fullScreenCover(isPresented: isAuthPendingUserSelectionBinding) {
            EmployeeList()
        }
    }
}

enum FullScreenCover: Hashable, Identifiable{
    case toZones
    case toQrScanner
    
    var id: Int{
        return self.hashValue
    }
}

struct EmployeeList: View {
    @EnvironmentObject var authManager: AuthManager
    @State var presentFullScreenCover: FullScreenCover? = nil

    class Model: ObservableObject {
        @Published var users: [Restaurant.RestaurantEmploye]?

        var _loadUsersCancellable: AnyCancellable!

        func loadUsers(from authManager: AuthManager) {
            _loadUsersCancellable = authManager.restaurant.loadUsers().sink(receiveCompletion: {
                [unowned self] result in
                self._loadUsersCancellable = nil
                // TODO: handle case .failure(let error) = result...
            }, receiveValue: { [unowned self] users in
                self.users = users
            })
        }
    }
    @StateObject var model = Model()

    @ViewBuilder var noUsersFoundErrorMessage: some View {
        Text("There are no pending users! Please contact your supervisor.")
            .bold()
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        Button(action: {
            self.presentFullScreenCover = .toQrScanner
        }, label: {
            Text("Retry Scan")
                .frame(width: 250, height: 50, alignment: .center)
                .foregroundColor(.blue)
                .background(Color.white)
                .cornerRadius(10)
        })
        .padding()
    }

    @ViewBuilder func userListing(restaurant: Restaurant, users: [Restaurant.RestaurantEmploye]) -> some View {
        Text("\(restaurant.name)")
            .bold()
            .foregroundColor(Color(UIColor.label))
            .padding(.top, 10)
            .font(.largeTitle)

        List{
            ForEach(users) { user in
                Button(action: {
                    // TODO: Handle potential error that can arise while marking user as inactive.
                    _ = authManager.finishWaiterLogin(withUser: user)
                }, label: {
                    HStack{
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color(UIColor.label))
                            .font(.custom("SF Symbols", size: 20))
                            .padding(.all, 5)

                        Text("\(user.name) \(user.lastName)")
                            .foregroundColor(Color(UIColor.label))
                            .padding(.all, 10)
                    }
                })
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    var body: some View {
        VStack {
            IfLet(model.users, whenPresent: { users in
                if users.count == 0 {
                    noUsersFoundErrorMessage
                } else {
                    userListing(restaurant: authManager.restaurant, users: users)
                }
            }, whenAbsent: {
                Spinner()
            })
        }
        .onAppear {
            model.loadUsers(from: authManager)
        }
        .navigationBarHidden(true)
        // TODO[pn 2021-07-09]: This is definitely not how this should work.
        // At the very least, this should be replaced all the way back in the
        // aptly-named LounchScreen [sic], not overlaid _on top_ of the QR
        // scanner, lest it cause a memory leak.
        .fullScreenCover(item: $presentFullScreenCover) { item in
            if item == .toZones{
//                ToZoneView(qrscanner: scannerWork)
                EmptyView()
            }else if item == .toQrScanner{
                ToQrScannerView()
            }
        }
    }
}
