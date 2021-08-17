//
//  ManagerView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 13/07/2021.
//

import SwiftUI

struct ManagerView: View {
    var body: some View {
        List {
            Section(header: Text("General")) {
                Text("No Controls Available").foregroundColor(.secondaryLabel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct ManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerView()
    }
}
#endif
