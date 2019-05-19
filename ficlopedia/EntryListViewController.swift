//
// Created 5/16/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import UIKit

class EntryListViewController: UIViewController {
    let db = Firestore.firestore()
    @IBOutlet weak var tableview: UITableView!
    var entries: [Entry] = [] {
        didSet {
            tableview.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let spinner = UIRefreshControl()
        tableview.refreshControl = spinner
        spinner.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshData()
    }
    
    @IBAction func didTapSignout(_ sender: UIBarButtonItem) {
        transitionToLoggedOut()
    }
    
    @objc
    private func refreshData() {
        db.collection("entries").getDocuments() { (querySnapshot, err) in
            self.tableview.refreshControl?.endRefreshing()
            self.entries = querySnapshot!.documents
                .compactMap {
                    try? JSONDecoder().decode(Entry.self, from: JSONSerialization.data(withJSONObject: $0.data(), options: []))
                }
                .sorted { $0.value < $1.value }
        }
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
        cell.textLabel?.text = entry.value
        cell.detailTextLabel?.text = entry.description
        return cell
    }
}

extension EntryListViewController: UITableViewDelegate {
    
}
