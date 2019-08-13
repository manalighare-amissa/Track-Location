//
//  PatientDetailViewController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 7/24/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit

protocol  PatientDetailViewDelegate{
    func didTapAddGeofence( )
    func didTapEnterRadius()
    func addedRegion(_ radius: Double,_ address: String)
}

class PatientDetailViewController: UIViewController, UITextFieldDelegate{
    
    
    var patientDetailDelegate: PatientDetailViewDelegate!
    
    @IBOutlet weak var addressLabel1: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var radiusTextField: UITextField!{
        didSet{
            self.radiusTextField.addDoneToolbar()
        }
    }
    @IBOutlet weak var geofenceCenterTextField: UITextField!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        radiusTextField.delegate = self
        geofenceCenterTextField.delegate = self
    }
    
    @IBAction func addGeofenceButtonTapped(_ sender: UIButton) {
        patientDetailDelegate.didTapAddGeofence()
    }
    
    @IBAction func enterRadiusTapped(_ sender: Any) {
        patientDetailDelegate.didTapEnterRadius()
    }
    
    @IBAction func startMonitoringButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
        if radiusTextField.text != nil && geofenceCenterTextField.text != nil{
            if let radius = Double(radiusTextField.text!){
                patientDetailDelegate.addedRegion(radius, geofenceCenterTextField.text!)
            }
        }
        
    }
}

extension UITextField{
    func addDoneToolbar(onDone: (target: Any, action: Selector)? = nil) {
       
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))
        
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    // Default actions:
    @objc func doneButtonTapped() { self.resignFirstResponder() }
}

