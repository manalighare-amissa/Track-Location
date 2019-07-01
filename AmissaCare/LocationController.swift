//
//  LocationController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 6/30/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit
import  CoreLocation

class LocationController: UIViewController {

    @IBOutlet weak var radius: UITextField!
    
    @IBOutlet weak var address: UITextField!
    
    lazy var geocoder = CLGeocoder()
    var locationLatitude: Double?
    var locationLongitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        address.delegate = self
        radius.delegate = self
    }
    
    @IBAction func locationMonitor(_ sender: UIButton) {
        //print("****")
        
    
        guard let addressText = address.text else { return }
        
        geocoder.geocodeAddressString(addressText) { (placemarks, error) in
            let placemark = placemarks?.first
            
            DispatchQueue.main.async {
                self.locationLatitude = placemark?.location?.coordinate.latitude
                self.locationLongitude = placemark?.location?.coordinate.longitude
                self.performSegue(withIdentifier: "showGeofencing", sender: self)
            }
            
        }
        
       
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGeofencing"{
            let destination = segue.destination as! ViewController
            destination.latitude = locationLatitude
            destination.longitude = locationLongitude
        }
        
        
    }
   

}

extension LocationController: UITextFieldDelegate{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

