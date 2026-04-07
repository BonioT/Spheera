//
//  BreathingTechniqueModel.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import Foundation

struct BreathingTechnique: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let inhaleDuration: TimeInterval
    let holdDuration: TimeInterval
    let exhaleDuration: TimeInterval

    var timing: String {
        "\(Int(inhaleDuration))-\(Int(holdDuration))-\(Int(exhaleDuration))"
    }

    static let presets: [BreathingTechnique] = [
        .init(
            name: String(localized: "Box Breathing"),
            description: String(localized: "Balances the nervous system and reduces stress."),
            inhaleDuration: 4,
            holdDuration: 4,
            exhaleDuration: 4
        ),
        .init(
            name: String(localized: "Relaxing Breath"),
            description: String(localized: "Promotes relaxation and helps with sleep."),
            inhaleDuration: 4,
            holdDuration: 7,
            exhaleDuration: 8
        ),
        .init(
            name: String(localized: "Mindful Breathing"),
            description: String(localized: "A simple technique to ground yourself in the present."),
            inhaleDuration: 5,
            holdDuration: 0,
            exhaleDuration: 5
        ),
        .init(
            name: String(localized: "Long Exhale"),
            description: String(localized: "Activates the parasympathetic nervous system to calm you down."),
            inhaleDuration: 4,
            holdDuration: 2,
            exhaleDuration: 6
        )
    ]
}
