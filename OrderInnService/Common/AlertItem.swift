//
//  AlertItem.swift
//  OrderInnService
//
//  Created by Ivars Ruģelis on 15/04/2021.
//

import SwiftUI
import AVFoundation

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button = .default(Text("OK"))

    var alert: Alert {
        Alert(title: title, message: message, dismissButton: dismissButton)
    }
}

enum Alerts {
    struct Template: Identifiable {
        let id = UUID()
        let title: Text
        let message: Text
        let dismissButton: Alert.Button = .default(Text("OK"))

        var alert: Alert {
            Alert(title: title, message: message, dismissButton: dismissButton)
        }
    }

    static let invalidCodeFormat = Template(
        title: Text("Invalid Code"),
        message: Text("The scanned code appears to be invalid. Please try again."))
    
    static let invalidDevice = Template(
        title: Text("Something Went Wrong"),
        message: Text("Could not display camera. Please restart the app and try again."))
    
    static let invalidQrCode = Template(
        title: Text("Invalid QR Code"),
        message: Text("This does not appear to be an OrderInn Service Login QR Code. Please try again."))

    static let emptyOrder = Template(
        title: Text("No Items Selected"),
        message: Text("Please add at least one item to the order to continue."))

    static let restrictedAction = Template(
        title: Text("This Action Is Restricted"),
        message: Text("You do not have access to this action. Please contact your supervisor."))
}

struct AlertTemplate: ViewModifier {
    let alert: Binding<Alerts.Template?>

    func body(content: Content) -> some View {
        content
            .alert(item: alert) { $0.alert }
    }
}
extension View {
    func alert(template: Binding<Alerts.Template?>) -> some View {
        modifier(AlertTemplate(alert: template))
    }
}
