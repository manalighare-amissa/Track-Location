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
    @IBOutlet weak var batteryButton: UIButton!
    @IBOutlet weak var NavigationBar: UINavigationBar!
    
    // Selected Patient Data
    var patientID: String?
    var PatientName: String?
    
    // Firebase Reference
    var ref: DatabaseReference!
    var heartrate: UInt16?
    var batteryPercentage: UInt16?
    
    //MARK: Location Manager and Map Configuration
    let locationManager:CLLocationManager = CLLocationManager()
    
    let annotation = MKPointAnnotation()
    var circleRenderer: MKCircleRenderer?
    
    var plat: Double?
    var plong: Double?
    var distance: Double?
    
    // Floating Panel Controller
    var fpc: FloatingPanelController!
    
    //Geocode
    lazy var geocoder = CLGeocoder()
    var geofenceLatitude: Double?
    var geofenceLongitude: Double?
    
    // Setup app delegate variable to retrieve registration Token
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var registrationToken:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBar.topItem?.title = "\(PatientName!)"
        mapView.delegate = self as? MKMapViewDelegate
        
        
        //Retrieve registration token from app delegate
        registrationToken = delegate.registrationToken
        
        //MARK: Floating Panel Configuration
        // Initialize a FloatingPanelController object.
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
            self.batteryPercentage = (snapshot!["BatteryLevel"] as? UInt16)!
            
            self.heartRateButton.setTitle(" \(self.heartrate!)", for: .normal)
            self.batteryButton.setTitle("\(self.batteryPercentage!)%", for: .normal)
            
            print("heartrate is:\(self.heartrate)")
            print("Battery is: \(self.batteryPercentage)")
            
        })
        
        ref?.child("\(patientID!)").child("location").observe(.value, with:{ (DataSnapshot) in
            
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.plat = snapshot!["lat"] as? Double
            self.plong = snapshot!["long"] as? Double
            
            self.annotation.coordinate = CLLocationCoordinate2D(latitude: self.plat!, longitude: self.plong!)
            self.mapView.addAnnotation(self.annotation)
            self.annotation.title = "\(self.PatientName!)'s Location"
            
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
    
    func haversineDinstance(la1: Double, lo1: Double, la2: Double, lo2: Double, radius: Double = 6367444.7) -> Double {
        
        let haversin = { (angle: Double) -> Double in
            return (1 - cos(angle))/2
        }
        
        let ahaversin = { (angle: Double) -> Double in
            return 2*asin(sqrt(angle))
        }
        
        // Converts from degrees to radians
        let dToR = { (angle: Double) -> Double in
            return (angle / 360) * 2 * .pi
        }
        
        let lat1 = dToR(la1)
        let lon1 = dToR(lo1)
        let lat2 = dToR(la2)
        let lon2 = dToR(lo2)
        
        let hDistance = radius * ahaversin(haversin(lat2 - lat1) + cos(lat1) * cos(lat2) * haversin(lon2 - lon1))
        return hDistance
    }
    
    func centerViewOnUserLocation(_ radius: Double) {
        
        let location = CLLocationCoordinate2D(latitude: geofenceLatitude!, longitude: geofenceLongitude!)
        let patientLocation = CLLocationCoordinate2D(latitude: plat!, longitude: plong!)
        
        let centerLat = (location.latitude + patientLocation.latitude) / 2
        let centerLong = (location.longitude + patientLocation.longitude) / 2
        
        print("lat is:\(centerLat)")
        
        let centerDistance = haversineDinstance(la1: patientLocation.latitude, lo1: patientLocation.longitude, la2: location.latitude, lo2: location.longitude)
        print("distance is:\(centerDistance)")
        let centerLocation = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLong)
        
        let region = MKCoordinateRegion(center: centerLocation, latitudinalMeters: radius + centerDistance + 2000, longitudinalMeters: radius + centerDistance + 2000)
        mapView.setRegion(region, animated: true)
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

extension PatientLocationAndInfoController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return
            MKOverlayRenderer()
        }
        circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer!.fillColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        circleRenderer!.alpha = 0.4
        return circleRenderer!
    }
}

extension PatientLocationAndInfoController: PatientDetailViewDelegate{
    func didTapAddGeofence() {
        fpc.move(to: .half, animated: true)
    }
    
    
    func addedRegion(_ radius: Double, _ address: String) {
        
        print("Radius is : \(radius)")

        fpc.move(to: .tip, animated: true)
        
        // Remove old overlays if any
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        
        //Set a geofence region
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if((error) != nil){
                print("Error", error ?? "")
            }
            if let placemark = placemarks?.first {
                 let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                 print("Lat: \(coordinates.latitude) -- Long: \(coordinates.longitude)")
             
             DispatchQueue.main.async {
                 self.geofenceLatitude = coordinates.latitude
                 self.geofenceLongitude = coordinates.longitude
                
                  // Show geofence region on the map
                let circle: MKOverlay = MKCircle(center: CLLocationCoordinate2DMake(self.geofenceLatitude!,self.geofenceLongitude!), radius: Double(radius))
                self.mapView.addOverlay(circle)
                        
                // Set zoom level considering geofence
                self.centerViewOnUserLocation(radius)
                
                //Add geofence to firebase
                let userID = Auth.auth().currentUser?.uid
                self.ref.child("\(self.patientID!)").child("Geofences").child("\(userID!)").child("center").child("lat").setValue(self.geofenceLatitude)
                self.ref.child("\(self.patientID!)").child("Geofences").child("\(userID!)").child("center").child("long").setValue(self.geofenceLongitude)
                self.ref.child("\(self.patientID!)").child("Geofences").child("\(userID!)").child("radius").setValue(radius)
                self.ref.child("\(self.patientID!)").child("Geofences").child("\(userID!)").child("registrationToken").setValue(self.registrationToken!)
                
                        
             }
                 
            }
        })
        
      
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
        case .half: return 230.0 // A bottom inset from the safe area
        case .tip: return 85.0 // A bottom inset from the safe area
        default: return nil // Or `case .hidden: return nil`
        }
    }
}
