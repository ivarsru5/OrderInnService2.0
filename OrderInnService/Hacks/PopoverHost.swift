//
//  PopoverPresenter.swift
//  OrderInnService
//
//  Created by paulsnar on 8/12/21.
//

import Foundation
import SwiftUI
import UIKit

// HACK[pn]: Given the weird behaviour surrounding .popover at least in iOS 15
// betas, it appears more reliable to reimplement popovers in UIKit ourselves.
// Also see issue #12.
// BUG[pn]: It appears that attaching an UIHostingController in the way we do
// now causes all the environment to be reset, so all EnvironmentObjects will
// not be resolvable in the popover content view and cause rendering to crash.
// I've tried constructing the popover content hosting controller within the
// base content controller initialiser as well, but it doesn't seem to do the
// trick. Therefore it's necessary to explicitly re-pass-in the environment
// objects that the popover view requires (for an example, see
// ActiveOrderDetailView which re-passes-in the MenuManager as an explicit
// environmentObject within the popover content.)
struct PopoverHost<BaseContent: View, Popover: View>: UIViewControllerRepresentable {
    typealias UIViewControllerType = Controller

    class Controller: UIHostingController<BaseContent>, UIAdaptivePresentationControllerDelegate {
        let isPopoverPresented: Binding<Bool>

        init(rootView: BaseContent, isPopoverPresented: Binding<Bool>) {
            self.isPopoverPresented = isPopoverPresented
            super.init(rootView: rootView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPopoverPresented.wrappedValue = false
        }

        func present(view baseView: Popover) {
            let view = baseView
                .environment(\.o6nIsPresented, true)
                .environment(\.o6nDismiss, DismissAction.custom(action: self.dismissModal))
            let vc = UIHostingController(rootView: view)
            vc.modalPresentationStyle = .popover
            vc.presentationController?.delegate = self

            present(vc, animated: true, completion: nil)
        }

        func dismissModal() {
            self.dismiss(animated: true, completion: nil)
        }

        override func dismiss(animated: Bool, completion: (() -> ())?) {
            super.dismiss(animated: animated, completion: { [self] in
                isPopoverPresented.wrappedValue = false
                completion?()
            })
        }
    }

    let baseContent: () -> BaseContent
    let popover: () -> Popover
    let popoverPresented: Binding<Bool>

    func makeUIViewController(context: Context) -> UIViewControllerType {
        return Controller(rootView: baseContent(), isPopoverPresented: popoverPresented)
    }

    func updateUIViewController(_ vc: UIViewControllerType, context: Context) {
        vc.rootView = baseContent()
        if let popover = vc.presentedViewController as? UIHostingController<Popover> {
            popover.rootView = self.popover()
        }

        let shouldDisplayPopover = popoverPresented.wrappedValue
        let isPopoverPresented = vc.presentedViewController != nil
        if shouldDisplayPopover && !isPopoverPresented {
            vc.present(view: popover())
        } else if !shouldDisplayPopover && isPopoverPresented {
            vc.dismiss(animated: true, completion: nil)
        }
    }
}
