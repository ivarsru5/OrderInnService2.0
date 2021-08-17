//
//  O6NButtonStyle.swift
//  OrderInnService
//
//  Created by paulsnar on 7/29/21.
//

import Combine
import Foundation
import SwiftUI

struct O6NMutedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let mod = O6NButtonStyle.Modifier(bg: .tertiarySystemBackground, fg: .label)
        return configuration.label
            .modifier(mod)
    }
}

struct O6NButtonStyle: ButtonStyle {
    let isLoading: Bool
    let isEnabled: Bool

    init(isLoading: Bool = false, isEnabled: Bool = true) {
        self.isLoading = isLoading
        self.isEnabled = isEnabled
    }

    static let transitionAnimation = Animation.easeOut(duration: 0.2)

    fileprivate struct Modifier: ViewModifier {
        let bg: Color
        let fg: Color

        func body(content: Content) -> some View {
            // NOTE[pn 2021-07-29]: This specific order of modifiers
            // has been found to work via a lot of trial-and-error.
            // If you're thinking of changing it, please make sure
            // no usage of this button style breaks as a result.
            content
                .multilineTextAlignment(.center)
                .font(.body.bold())
                .foregroundColor(fg)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(bg)
                .cornerRadius(16)
                .padding(16)
        }
    }

    @ViewBuilder func makeBody(configuration: Configuration) -> some View {
        if isLoading {
            ActivityIndicator(style: .medium)
                .modifier(Modifier(bg: .gray3, fg: .label))
        } else if !isEnabled {
            configuration.label
                .modifier(Modifier(bg: .secondaryLabel, fg: .secondarySystemBackground))
        } else {
            configuration.label
                .modifier(Modifier(bg: .label, fg: .systemBackground))
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

            var sub: AnyCancellable?
            sub = Just(())
                .delay(for: .seconds(3), scheduler: RunLoop.main)
                .ignoreOutput()
                .sink(receiveCompletion: { _ in
                    withAnimation(O6NButtonStyle.transitionAnimation) {
                        isLoading = false
                    }
                    if let _ = sub {
                        sub = nil
                    }
                })
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

            Button(action: noop, label: {
                Text("Disabled Button")
            })
            .buttonStyle(O6NButtonStyle(isEnabled: false))

            TestButton()

            Button(action: noop, label: {
                Text("Muted Button")
            })
            .buttonStyle(O6NMutedButtonStyle())
        }
    }

    static var previews: some View {
        makeButtonStack()

        makeButtonStack()
            .preferredColorScheme(.dark)
    }
}
#endif
