//
// Created 5/18/19
// Copyright © 2019 Intro To FI. All rights reserved.
//

import UIKit

class EntryDetailViewController: UIViewController {
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
    }
    
    func configure(with entry: Entry) {
        self.entry = entry
    }
}
