//
//  TableSelectionView.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 21/04/2021.
//

import SwiftUI

struct TableSelectionView: View {
    @StateObject var tables = TableSelectionWork()
    @ObservedObject var zones: ZoneWork
    
    var body: some View {
        List{
            ForEach(tables.tables, id:\.id){ table in
                Text("\(table.table)")
                    .bold()
                    .foregroundColor(Color(UIColor.label))
            }
        }
        //.navigationBarTitle(Text("\(zones.selectedZone!.location)"))
        .onAppear{
            tables.getTables(with: zones.selectedZone!.id)
        }
    }
}
