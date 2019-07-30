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
    func addedRegion()
}

class PatientDetailViewController: UIViewController, UITextFieldDelegate{
    
    
    var patientDetailDelegate: PatientDetailViewDelegate!
    
    @IBOutlet weak var addressLabel1: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var radiusTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        radiusTextField.delegate = self
    }
    
    @IBAction func addGeofenceButtonTapped(_ sender: UIButton) {
        patientDetailDelegate.didTapAddGeofence()
    }
    
    @IBAction func enterRadiusTapped(_ sender: Any) {
        patientDetailDelegate.didTapEnterRadius()
    }
    
    @IBAction func startMonitoringButtonTapped(_ sender: Any) {
    patientDetailDelegate.addedRegion()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        radiusTextField.resignFirstResponder()
        patientDetailDelegate.addedRegion()
        return true
    }
    
    
}

