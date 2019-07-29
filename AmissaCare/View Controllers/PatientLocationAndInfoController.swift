//
//  PatientLocationAndInfoController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 7/29/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications
import Firebase
import FirebaseDatabase
import FloatingPanel


class PatientLocationAndInfoController: UIViewController {

    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var heartRateButton: UIButton!
    @IBOutlet weak var NavigationBar: UINavigationBar!
    
    // Selected Patient Data
    var patientID: String?
    var PatientName: String?
    
    // Firebase Reference
    var ref: DatabaseReference!
    var heartrate: UInt16?
    
    //MARK: Location Manager and Map Configuration
    let locationManager:CLLocationManager = CLLocationManager()
    
    let annotation = MKPointAnnotation()
    var circleRenderer: MKCircleRenderer?
    
    var latitude: Double?
    var longitude: Double?
    var geofenceRadius: Double?
    
    var plat: Double?
    var plong: Double?
    var distance: Double?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBar.topItem?.title = "\(PatientName!)"
        
        // MARK: Firebase Listeners
        ref = Database.database().reference()
        
        ref?.child("\(patientID!)").observe(.value, with: { (DataSnapshot) in
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.heartrate = snapshot!["heartRate"] as? UInt16
            self.heartRateButton.setTitle("\(self.heartrate!)", for: .normal)
            print("heartrate is:\(self.heartrate)")
            
        })
        
        ref?.child("\(patientID!)").child("location").observe(.value, with:{ (DataSnapshot) in
            
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.plat = snapshot!["lat"] as? Double
            self.plong = snapshot!["long"] as? Double
            
            self.annotation.coordinate = CLLocationCoordinate2D(latitude: self.plat!, longitude: self.plong!)
            self.mapView.addAnnotation(self.annotation)
            self.annotation.title = "Patient's Location"
            
            // MARK: Reverse geocoding for patient location
            
            let center = CLLocation(latitude: self.plat!, longitude: self.plong!)
            let geoCoder = CLGeocoder()
            
            geoCoder.reverseGeocodeLocation(center, completionHandler: {(data,error) -> Void in
                let placeMarks = data as! [CLPlacemark]
                let loc: CLPlacemark = placeMarks[0]
                
                self.mapView.centerCoordinate = center.coordinate
                let city = loc.locality ?? ""
                let streetNumber = loc.subThoroughfare ?? ""
                let streetName = loc.thoroughfare ?? ""
                let subLocality = loc.subLocality ?? ""
               
                // self.addressLabel.text = "\(streetNumber) \(streetName) \(subLocality) \(city)"
               // self.centerViewOnUserLocation()
            })
        })
        
    }
    
    
    


}
