//
//  SignInController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 7/9/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore

class SignInController: UIViewController {
    
    
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createNewAccount: UIButton!
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            
            self.performSegue(withIdentifier: "LoginToPatientListSegue", sender: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.delegate = self
        passwordLabel.delegate = self 
        
    }
    
    @IBAction func onClickCreateNewAccount(_ sender: Any) {
        self.performSegue(withIdentifier: "goToSignUpSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSignUpSegue" {
            let vc = segue.destination as! SignUpController
        }
    }
    
    @IBAction func onClickLoginButton(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailLabel.text!, password: passwordLabel.text!) { (user, error) in
            if error == nil{
                print (" no error")
                self.performSegue(withIdentifier: "LoginToPatientListSegue", sender: self)
            }
            else{
                print ("error")
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

}

extension SignInController: UITextFieldDelegate{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
}
