//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import FirebaseDatabase
import FirebaseFirestore
import UIKit

class EntryDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var saveButton: UIBarButtonItem!
    var selectedCategory: Category?
    
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
    
    @IBAction func didTapStatusButton(_ sender: UIButton) {
        select(options: EntryStatus.statuses, forButton: statusButton)
    }
    
    @IBAction func didTapCategoryButton(_ sender: UIButton) {
        selectCategory(options: Store.categories, forButton: categoryButton)
    }
    
    @objc
    func didTapSave() {
        do {
            guard let entry = entry, case .saved = entry.id else { try createNewEntry(); return }
            try save(entry)
        } catch {
            let alertController = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Try Again", style: .default) { _ in
                self.didTapSave()
            }
            alertController.addAction(yesAction)
            alertController.preferredAction = yesAction
            alertController.addAction(.init(title: "Cancel", style: .default))
            present(alertController, animated: true)
        }
    }
    
    @IBAction func didtapTrash(_ sender: UIBarButtonItem) {
        guard let entry = entry else { return }
        delete(entry)
    }
    
    private func select(options: [EntryStatus], forButton button: UIButton) {
        var datasource: SimpleTableViewDataAndDelegate?
        datasource = SimpleTableViewDataAndDelegate(options: options) { option in
            self.navigationController?.popViewController(animated: true)
            button.setTitle(option.name, for: .normal)
            self.hasEdits = true
            datasource = nil
        }
        let tvc = UITableViewController()
        tvc.tableView.tableFooterView = UIView()
        tvc.tableView.dataSource = datasource
        tvc.tableView.delegate = datasource
        tvc.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationController?.pushViewController(tvc, animated: true)
        tvc.tableView.reloadData()
    }

    private func selectCategory(options: [Category], forButton button: UIButton) {
        var datasource: SimpleTableViewDataAndDelegate?
        datasource = SimpleTableViewDataAndDelegate(options: options) { option in
            self.navigationController?.popViewController(animated: true)
            button.setTitle(option.name, for: .normal)
            self.selectedCategory = option as? Category
            self.hasEdits = true
            datasource = nil
        }
        let tvc = UITableViewController()
        tvc.tableView.tableFooterView = UIView()
        tvc.tableView.dataSource = datasource
        tvc.tableView.delegate = datasource
        tvc.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationController?.pushViewController(tvc, animated: true)
        tvc.tableView.reloadData()
    }

    class SimpleTableViewDataAndDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
        let options: [Optionable]
        let onSelectRow: (Optionable) -> ()
        init(options: [Optionable], onSelectRow: @escaping (Optionable) -> ()) {
            self.options = options.filter { $0.optionId != nil }
            self.onSelectRow = onSelectRow
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return options.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = options[indexPath.row].name
            cell.detailTextLabel?.text = options[indexPath.row].subName
            return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            onSelectRow(options[indexPath.row])
        }
    }
    
    private func save(_ entry: Entry) throws {
        guard case let .saved(id) = entry.id, case let .saved(rtdKey) = entry.rtdKey, let entry = entryFromForm, let json = try entry.json() else { return }
        Database.database().reference(withPath: "entries/\(rtdKey)").updateChildValues(json)
        db.document("entries/\(id)").updateData(json) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func createNewEntry() throws {
        guard let entry = entryFromForm, var json = try entry.json() else { return }
        let ref = Database.database().reference(withPath: "entries").childByAutoId()
        ref.setValue(json)
        json["rtdKey"] = ref.key
        db.collection("entries").addDocument(data: json) { error in
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
            let status = EntryStatus(rawValue: statusText),
            let category = selectedCategory?.id else { return nil}
        return Entry(id: entry?.id ?? .unsaved, value: value, description: description, status: status, categoryID: category, rtdKey: entry?.rtdKey ?? .unsaved)
    }
    
    private func delete(_ entry: Entry) {
        guard case let .saved(id) = entry.id else { return }
        let alertController = UIAlertController(title: "Delete Entry", message: "Are you sure?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            Database.database().reference(withPath: "entries/\(id)").removeValue()
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
        categoryLabel.text = "Category"
        valueLabel.text = "Value"
        valueTextField.delegate = self
        valueTextField.autocapitalizationType = .words
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
        title = entry?.value
        statusButton.setTitle(entry?.status.rawValue ?? "[Set Status]", for: .normal)
        selectedCategory = Store.categories.first { entry?.categoryID == $0.id }
        categoryButton.setTitle(selectedCategory?.name ?? "[Set Category]", for: .normal)
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
