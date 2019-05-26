//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseFirestore
import UIKit

class EntryDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var saveButton: UIBarButtonItem!
    
    private let db = Firestore.firestore()
    
    var entry: Entry?
    private var hasEdits: Bool = false {
        didSet {
            if hasEdits {
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
                if !(navigationItem.rightBarButtonItems?.contains(saveButton) ?? false) {
                    navigationItem.rightBarButtonItems?.append(saveButton)
                }
            } else {
                navigationItem.leftBarButtonItem = nil
                navigationItem.rightBarButtonItems?.removeAll(where: { $0 === saveButton })
            }
        }
    }
    
    @objc
    private func didTapCancel() {
        load(from: entry)
        hasEdits = false
        view.endEditing(false)
    }
    
    @IBAction func didTapStatusButton(_ sender: Any) {
        selectStatus()
    }
    
    @objc
    func didTapSave() {
        guard let entry = entry else { createNewEntry(); return }
        save(entry)
    }
    
    @IBAction func didtapTrash(_ sender: UIBarButtonItem) {
        guard let entry = entry else { return }
        delete(entry)
    }
    
    private func selectStatus() {
        var datasource: SimpleTableViewDataAndDelegate?
        datasource = SimpleTableViewDataAndDelegate(strings: EntryStatus.statuses, subStrings: nil) { indexPath in
            self.dismiss(animated: true) {
                self.statusButton.setTitle(EntryStatus.statuses[indexPath.row], for: .normal)
                self.hasEdits = true
                datasource = nil
            }
        }
        let tvc = UITableViewController()
        tvc.tableView.tableFooterView = UIView()
        tvc.tableView.dataSource = datasource
        tvc.tableView.delegate = datasource
        tvc.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        present(tvc, animated: true) {
            tvc.tableView.reloadData()
        }
    }
    
    class SimpleTableViewDataAndDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
        let strings: [String]
        let subStrings: [String]?
        let onSelectRow: (IndexPath) -> ()
        init(strings: [String], subStrings: [String]?, onSelectRow: @escaping (IndexPath) -> ()) {
            self.strings = strings
            self.subStrings = subStrings
            self.onSelectRow = onSelectRow
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return strings.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = strings[indexPath.row]
            return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            onSelectRow(indexPath)
        }
    }
    
    private func save(_ entry: Entry) {
        guard let id = entry.id, let entry = entryFromForm else { return }
        db.document("entries/\(id)").updateData(entry.data) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func createNewEntry() {
        guard let entry = entryFromForm else { return }
        db.collection("entries").addDocument(data: entry.data) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private var entryFromForm: Entry? {
        guard let value = valueTextField.text,
            let description = descriptionTextView.text,
            let statusText = statusButton.titleLabel?.text,
            let status = EntryStatus(rawValue: statusText) else { return nil}
        return Entry(id: entry?.id, value: value, description: description, status: status)
    }
    
    private func delete(_ entry: Entry) {
        guard let id = entry.id else { return }
        let alertController = UIAlertController(title: "Delete Entry", message: "Are you sure?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            self.db.document("entries/\(id)").delete { error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(yesAction)
        alertController.preferredAction = yesAction
        alertController.addAction(.init(title: "Cancel", style: .default))
        present(alertController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load(from: entry)
        saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
        statusLabel.text = "Status"
        valueLabel.text = "Value"
        valueTextField.delegate = self
        descriptionLabel.text = "Description"
        descriptionTextView.delegate = self
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = UIColor(white: 210.0/255.0, alpha: 1).cgColor
        descriptionTextView.layer.cornerRadius = 5
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func configure(with entry: Entry) {
        self.entry = entry
    }
    
    private func load(from entry: Entry?) {
        statusButton.setTitle(entry?.status.rawValue ?? "[Set Status]", for: .normal)
        valueTextField.text = entry?.value
        descriptionTextView.text = entry?.description
    }
    
    @objc
    private func keyboardDidShow(notification: NSNotification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardEnd = value.cgRectValue
        scrollView.contentInset = .init(top: 0, left: 0, bottom: keyboardEnd.height, right: 0)
    }
    
    @objc
    private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension EntryDetailViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        hasEdits = true
        return true
    }
}

extension EntryDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        hasEdits = true
        return true
    }
}
