//
//  ActivityIndicatior.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 19/04/2021.
//

import SwiftUI

struct Spinner: View {
    fileprivate struct Frame: ViewModifier {
        let frame: CGRect

        func body(content: Content) -> some View {
            let width = frame.width / 3.5

            return content
    //            .offset(x: (frame.width - width) / 2,
    //                    y: (frame.height - width) / 2)
                .frame(width: width, height: width, alignment: .center)
                .cornerRadius(width / 8)
        }
    }

    var body: some SwiftUI.View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    path.addRect(geometry.frame(in: .local))
                }
                    .fill(Color(UIColor.systemBackground))
                    .opacity(0.5)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)

                Group {
                    BlurEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
                    
                    ActivityIndicator(style: .large)
                }
                    .modifier(Frame(frame: geometry.frame(in: .local)))
            }
        }
    }
}
