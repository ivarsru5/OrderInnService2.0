//
//  O6NButtonStyle.swift
//  OrderInnService
//
//  Created by paulsnar on 7/29/21.
//

import Foundation
import SwiftUI

struct O6NButtonStyle: ButtonStyle {
    let isLoading: Bool

    init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }

    static let transitionAnimation = Animation.easeOut(duration: 0.2)

    @ViewBuilder func makeBody(configuration: Configuration) -> some View {
        if isLoading {
            ActivityIndicator(style: .medium)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.gray3)
                .cornerRadius(16)
                .padding(16)
        } else {
            configuration.label
                .font(.body.bold())
                .foregroundColor(.systemBackground)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.label)
                .cornerRadius(16)
                .padding(16)
        }
    }
}

#if DEBUG
struct O6NButtonStylePreviews: PreviewProvider {
    static func noop() { }

    struct TestButton: View {
        @State var isLoading = false

        func load() {
            guard !isLoading else { return }
            withAnimation(O6NButtonStyle.transitionAnimation) {
                isLoading = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(3))) {
                withAnimation(O6NButtonStyle.transitionAnimation) {
                    isLoading = false
                }
            }
        }

        var body: some View {
            Button(action: load, label: {
                Text("Tap To Load")
            })
                .buttonStyle(O6NButtonStyle(isLoading: isLoading))
        }
    }

    @ViewBuilder static func makeButtonStack() -> some View {
        VStack {
            Button(action: noop, label: {
                Text("Test Button")
            })
                .buttonStyle(O6NButtonStyle())

            Button(action: noop, label: {
                Text("Loading Button")
            })
                .buttonStyle(O6NButtonStyle(isLoading: true))

            TestButton()
        }
    }

    static var previews: some View {
        makeButtonStack()

        makeButtonStack()
            .preferredColorScheme(.dark)
    }
}
#endif
