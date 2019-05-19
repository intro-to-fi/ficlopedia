//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import UIKit

class EntryDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var entry: Entry?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        valueLabel.text = "Value"
        valueTextField.text = entry?.value
        descriptionLabel.text = "Description"
        descriptionTextView.text = entry?.description
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func configure(with entry: Entry) {
        self.entry = entry
    }
    
    @objc
    func keyboardDidShow(notification: NSNotification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardEnd = value.cgRectValue
        scrollView.contentInset = .init(top: 0, left: 0, bottom: keyboardEnd.height, right: 0)
    }
    @objc
    func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0)
    }
}
