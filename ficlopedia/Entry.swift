//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import Foundation

struct Entry: FirebaseCodable {
    let id: String
    let value: String
    let description: String
}

protocol FirebaseCodable: Decodable {
    var id: String { get }
}
