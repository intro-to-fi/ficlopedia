//
// Created 5/27/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import Foundation

class Debouncer {
    weak var timer: Timer?
    func debounce(interval: TimeInterval = 0.35, action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            action()
        }
    }
}
