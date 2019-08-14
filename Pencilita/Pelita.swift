//
//  Pelita.swift
//  Pencilita
//
//  Created by Rike-Benjamin Schuppner on 13.08.19.
//  Copyright © 2019 Rike-Benjamin Schuppner. All rights reserved.
//

import Foundation

struct Bot : Decodable {
    let walls: [Point]
    let bots: [Point]
    let score: [Int]
    let food: [[Point]]
    let turn: Int
    let round: Int
}

struct Point : Decodable {
    let x: Int
    let y: Int
    
    init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        x = try values.decode(Int.self)
        y = try values.decode(Int.self)
    }
}
