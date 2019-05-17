//
// Created 5/16/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import UIKit

class EntryListViewController: UIViewController {
  @IBOutlet weak var tableview: UITableView!
  var entries: [String] = ["Test", "Foobar"] {
        didSet {
            tableview.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let db = Firestore.firestore()
        db.collection("entries").getDocuments() { (querySnapshot, err) in
            self.entries = querySnapshot!.documents.map { $0.data()["value"] as! String }
//            if let err = err {
//                print("Error getting documents: \(err)")
//            } else {
//                for document in querySnapshot!.documents {
//                    print("\(document.documentID) => \(document.data())")
//                }
//            }
        }

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
