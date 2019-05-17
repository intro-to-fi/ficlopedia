//
// Created 5/16/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseAuth
import UIKit

class EntryListViewController: UIViewController {
    var entries: [String] = ["Test", "Foobar"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapSignout(_ sender: UIBarButtonItem) {
        transitionToLoggedOut()
    }
    
    private func transitionToLoggedOut() {
        if let window = UIApplication.shared.keyWindow {
            do {
                try Auth.auth().signOut()
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
                    window.rootViewController = vc
                }, completion: { completed in
                    // maybe do something here
                })
            } catch {
                print(error)
            }
        }
    }
}

extension EntryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "entryListViewCell", for: indexPath)
        let entry = entries[indexPath.row]
        cell.textLabel?.text = entry
        return cell
    }
}

extension EntryListViewController: UITableViewDelegate {
    
}
