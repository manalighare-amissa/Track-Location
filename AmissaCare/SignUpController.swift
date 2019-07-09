//
//  SignUpController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 7/9/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class SignUpController: UIViewController {
    
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var confirmPasswordLabel: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.delegate = self
        emailLabel.delegate = self
        passwordLabel.delegate = self
        confirmPasswordLabel.delegate = self
    }
    
    @IBAction func onClickCancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        dismiss(animated: true) {
            
        }
    }
    
    
    @IBAction func onClickSubmitButton(_ sender: Any) {
        if passwordLabel.text != confirmPasswordLabel.text {
            let alertController = UIAlertController(title: "Password Incorrect", message: "Please re-type password", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            Auth.auth().createUser(withEmail: emailLabel.text!, password: passwordLabel.text!){ (user, error) in
                if error == nil {
                    self.performSegue(withIdentifier: "signUpToHomeSegue", sender: self)
                }
                else{
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

}

extension SignUpController: UITextFieldDelegate{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
