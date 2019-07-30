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


class PatientLocationAndInfoController: UIViewController, FloatingPanelControllerDelegate {

    
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
    
    // Floating Panel Controller
    var fpc: FloatingPanelController!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBar.topItem?.title = "\(PatientName!)"
        
        //MARK: Floating Panel Configuration
        // Initialize a `FloatingPanelController` object.
        fpc = FloatingPanelController()
        
        // Assign self as the delegate of the controller.
        fpc.delegate = self
        
        
        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.shadowHidden = false
        
        
        // Set a content view controller.
        let contentVC = storyboard?.instantiateViewController(withIdentifier: "PatientDetailViewController") as? PatientDetailViewController
        
        contentVC?.patientDetailDelegate = self as! PatientDetailViewDelegate
        
        fpc.set(contentViewController: contentVC)
        
        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: contentVC?.scrollView)
        
        // Add and show the views managed by the `FloatingPanelController` object to self.view.
        fpc.addPanel(toParent: self)
        
        fpc.isRemovalInteractionEnabled = false
        
        
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
                let Name = loc.name ?? ""
                let postalCode = loc.postalCode ?? ""
                
                contentVC?.addressLabel1.text = " \(self.PatientName!)'s Location: \n \(Name)\n \(city), \(postalCode) "
                //contentVC?.addressLabel2.text = "\(city),\(postalCode)"
               // self.centerViewOnUserLocation()
            })
        })
        
    }
    
    // MARK: FloatingPanelControllerDelegate
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
    
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        
    }
    
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            
        }
    }
    
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition != .full {
            // searchVC.hideHeader()
        }
        
    }
    
    
    
    @IBAction func onClickLogoutButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        }
        catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initial = storyboard.instantiateInitialViewController()
        UIApplication.shared.keyWindow?.rootViewController = initial
        
    }
    
    
    


}

extension PatientLocationAndInfoController: PatientDetailViewDelegate{
    func didTapAddGeofence() {
        fpc.move(to: .half, animated: true)
    }
    
    func addedRegion() {
        print("called added region method")
        fpc.move(to: .tip, animated: true)
    }
    
    func didTapEnterRadius() {
        fpc.move(to: .full, animated: true)
    }
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 50.0 // A top inset from safe area
        case .half: return 216.0 // A bottom inset from the safe area
        case .tip: return 90.0 // A bottom inset from the safe area
        default: return nil // Or `case .hidden: return nil`
        }
    }
}
