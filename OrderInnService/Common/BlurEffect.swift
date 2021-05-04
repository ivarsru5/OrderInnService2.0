//
//  BlurEffect.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI

struct BlurEffectView: UIViewRepresentable{
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct ActivityIndicator: UIViewRepresentable {
    typealias UIViewType = UIActivityIndicatorView

    var style: UIActivityIndicatorView.Style = .medium

    func makeUIView(context: Context) -> UIViewType {
        let view = UIActivityIndicatorView(style: style)
        view.startAnimating()
        return view
    }

    func updateUIView(_ view: UIActivityIndicatorView, context: Context) {
        // noop...
    }

    static func dismantleUIView(_ view: UIActivityIndicatorView, coordinator: Void) {
        view.stopAnimating()
    }
}
