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
     @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    let locationManager:CLLocationManager = CLLocationManager()
    let regionInMeters: Double = 800
    
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    
    let annotation = MKPointAnnotation()
    
    var latitude: Double?
    var longitude: Double?
    var geofenceRadius: Double?
    
    var lat: Double?
    var long: Double?
    var distance: Double?
    
    var ref: DatabaseReference!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        ref = Database.database().reference()
        
        ref?.child("ccNCzyAUZEYVV9utgCk7fezqq623").child("location").observe(.value, with:{ (DataSnapshot) in
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.lat = snapshot!["lat"] as? Double
            self.long = snapshot!["long"] as? Double

            //print("lat = \(String(describing: self.lat)), Long = \(String(describing: self.long))")
            
            self.annotation.coordinate = CLLocationCoordinate2D(latitude: self.lat!, longitude: self.long!)
            self.mapView.addAnnotation(self.annotation)
            self.annotation.title = "Patient's Location"
            
            let center = CLLocation(latitude: self.lat!, longitude: self.long!)
            let geoCoder = CLGeocoder()
            
            self.checkWithinGeofenceRegion()
            
        
            geoCoder.reverseGeocodeLocation(center, completionHandler: {(data,error) -> Void in
                let placeMarks = data as! [CLPlacemark]
                let loc: CLPlacemark = placeMarks[0]
                
                self.mapView.centerCoordinate = center.coordinate
                let city = loc.locality ?? ""
                let streetNumber = loc.subThoroughfare ?? ""
                let streetName = loc.thoroughfare ?? ""
                let subLocality = loc.subLocality ?? ""
                self.addressLabel.text = "\(streetNumber) \(streetName) \(subLocality) \(city)"
                
                self.centerViewOnUserLocation()
            })
        })
        
      
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
    
    func checkWithinGeofenceRegion(){
        
        let geofenceCenter = CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
        let PatientLocation = CLLocationCoordinate2D(latitude: self.lat!, longitude: self.long!)
        distance = 0
        distance = haversineDinstance(la1: geofenceCenter.latitude, lo1: geofenceCenter.longitude, la2: PatientLocation.latitude, lo2: PatientLocation.longitude)
        
        if (Double(distance!) <= Double(geofenceRadius!)){
            print("inside")
            
            content.title = "Patient Location Update"
            content.body = "Patient is inside the monitored region"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
        
        }else{
            print("outside")
            
            content.title = "Patient Location Update"
            content.body = "Patient is outside of the monitored region"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
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
        
        let location = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = 100
            center.requestAuthorization(options: [.alert, .sound]) {(granted,error) in }
            
        let geoFenceRegion: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(latitude!,longitude!), radius: geofenceRadius!, identifier: "Monitored Region")
            locationManager.startMonitoring(for: geoFenceRegion)
        
        let circle = MKCircle(center: CLLocationCoordinate2DMake(latitude!,longitude!), radius: geofenceRadius!)
            mapView.addOverlay(circle)
        
        
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
    }
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return
            MKOverlayRenderer()
        }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        //circleRenderer.strokeColor = nil
        circleRenderer.fillColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        circleRenderer.alpha = 0.1
        return circleRenderer
    }
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region")
    }
}








