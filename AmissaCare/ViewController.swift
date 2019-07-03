//
//  ViewController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 6/24/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//



import UIKit
import MapKit
import CoreLocation
import UserNotifications
import Firebase
import FirebaseDatabase

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    let locationManager:CLLocationManager = CLLocationManager()
    let regionInMeters: Double = 8000
    
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    
    let annotation = MKPointAnnotation()
    
    var latitude: Double?
    var longitude: Double?
    
    
    var lat: Double?
    var long: Double?
    
    var ref: DatabaseReference!
    
    
    //var previousLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        ref = Database.database().reference()
        
        ref?.child("BB2b8n8hbZYdBerINFismvl454W2").child("location").observe(.value, with:{ (DataSnapshot) in
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.lat = snapshot!["lat"] as? Double
            self.long = snapshot!["long"] as? Double

            print("lat = \(String(describing: self.lat)), Long = \(String(describing: self.long))")
            
            self.annotation.coordinate = CLLocationCoordinate2D(latitude: self.lat!, longitude: self.long!)
            self.mapView.addAnnotation(self.annotation)
            self.annotation.title = "Patient's Location"
        })
        
      
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupLocationManager(){
        locationManager.delegate = self
        mapView.delegate = self as? MKMapViewDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func centerViewOnUserLocation() {
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
            //mapView.showsUserLocation = true
            
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = 1
            center.requestAuthorization(options: [.alert, .sound]) {(granted,error) in }
            
            let geoFenceRegion: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(latitude!,longitude!), radius: 1, identifier: "Charlotte")

            
            content.title = "Patient Location Update"
            content.body = "Patient exited the monitored region"
            content.sound = UNNotificationSound.default
            
            locationManager.startMonitoring(for: geoFenceRegion)
            //print(locationManager.monitoredRegions)
        }
    }
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
            let Alert = UIAlertController(title: "Need Permission", message: "Please turn location service on", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            Alert.addAction(cancel)
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            startTackingUserLocation()
        case .authorizedWhenInUse:
            break
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        }
    }
    
    func startTackingUserLocation() {
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        //previousLocation = getCenterLocation(for: mapView)
    }
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        centerViewOnUserLocation()
        let center = locations[0] as CLLocation
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(center, completionHandler: {(data,error) -> Void in
            let placeMarks = data as! [CLPlacemark]
            let loc: CLPlacemark = placeMarks[0]
            
            self.mapView.centerCoordinate = center.coordinate
            let city = loc.locality ?? ""
            let streetNumber = loc.subThoroughfare ?? ""
            let streetName = loc.thoroughfare ?? ""
            let subLocality = loc.subLocality ?? ""
            self.addressLabel.text = "\(streetNumber) \(streetName) \(subLocality),\(city)"
            //self.addressLabel.text = "\(self.latitude!) \(self.longitude!)"
            
            self.centerViewOnUserLocation()
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region")
    
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        print("Exited region")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}






