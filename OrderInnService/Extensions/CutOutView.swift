//
//  PathExtension.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI

extension View {
    public func inverseMask<M: View>(_ mask: M) -> some View {
        let inversed = mask
            .foregroundColor(.black)
            .background(Color.white)
            .compositingGroup()
            .luminanceToAlpha()
        return self.mask(inversed)
    }
}
