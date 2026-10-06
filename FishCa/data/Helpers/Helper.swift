//
//  Helper.swift
//  FishCa
//
//  Created by Kirill Sysoev on 05.10.2026.
//

import Foundation

struct Participant: Codable, Equatable {
    let id: Int
    let name: String
    var scores: [Double]
    var kilos: Double
    static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id
    }
}

var participants: [Participant] = []

func addParticipant() {
    participants.append(Participant(id: participants.count + 1, name: "Имя участника №\(participants.count + 1)", scores: [], kilos: 0))
    saveParticipants()
}


// MARK: UserDefaults

func saveParticipants() {
    if let encoded = try? JSONEncoder().encode(participants) {
        UserDefaults.standard.set(encoded, forKey: "participants")
    }
}

func downloadParticipants() {
    if let data = UserDefaults.standard.data(forKey: "participants") {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([Participant].self, from: data) {
            participants = decoded
        }
    }
}

func saveState(state: Bool) {
    UserDefaults.standard.set(state, forKey: "state")
}

func downloadState() -> Bool {
    guard let state = UserDefaults.standard.object(forKey: "state") as? Bool else {
        return false
    }
    return state
}

extension [Double] {
    func countKilos() -> Double {
        self.reduce(0, +)
    }
}
