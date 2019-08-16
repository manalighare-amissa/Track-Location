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
import FloatingPanel

class PatientInfoController: UIViewController,FloatingPanelControllerDelegate{
    
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var heartRateButton: UIButton!
    
    // Selected Patient Data
    var patientID: String?
    var PatientName: String?
    
    // Notification Configuration
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    
    
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
    
    // Firebase Reference
    var ref: DatabaseReference!
    var heartrate: UInt16?
    
    // Floating Panel Controller
    var fpc: FloatingPanelController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        
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
        fpc.set(contentViewController: contentVC)
        
        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: contentVC?.scrollView)
        
        // Add and show the views managed by the `FloatingPanelController` object to self.view.
        fpc.addPanel(toParent: self)
        
        fpc.isRemovalInteractionEnabled = true
        
        // MARK: Firebase Listeners
        ref = Database.database().reference()
        
        ref?.child("\(patientID)").observe(.value, with: { (DataSnapshot) in
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.heartrate = snapshot!["heartRate"] as? UInt16
            self.heartRateButton.setTitle("\(self.heartrate!)", for: .normal)
            print("heartrate is:\(self.heartrate)")
            
        })
        
        ref?.child("\(patientID)").child("location").observe(.value, with:{ (DataSnapshot) in
            
            let snapshot = DataSnapshot.value as? NSDictionary
            
            self.plat = snapshot!["lat"] as? Double
            self.plong = snapshot!["long"] as? Double
            
            // print("lat is: \(self.plat)")
            
            //print("lat = \(String(describing: self.lat)), Long = \(String(describing: self.long))")
            
            self.annotation.coordinate = CLLocationCoordinate2D(latitude: self.plat!, longitude: self.plong!)
            self.mapView.addAnnotation(self.annotation)
            self.annotation.title = "Patient's Location"
            
            self.checkWithinGeofenceRegion()
            
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
                self.addressLabel.text = "\(streetNumber) \(streetName) \(subLocality) \(city)"
                
                self.centerViewOnUserLocation()
            })
        })
        
        
        // Request location authorization
        locationManager.requestAlwaysAuthorization()
        
        // Geofence Region
        let geoFenceRegion: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(latitude!,longitude!), radius: geofenceRadius!, identifier: "Monitored Region")
        locationManager.startMonitoring(for: geoFenceRegion)
        
        // Circle overlay for geofence region
        let circle = MKCircle(center: CLLocationCoordinate2DMake(latitude!,longitude!), radius: geofenceRadius!)
        mapView.addOverlay(circle)
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
        let PatientLocation = CLLocationCoordinate2D(latitude: self.plat!, longitude: self.plong!)
        distance = 0
        distance = haversineDinstance(la1: geofenceCenter.latitude, lo1: geofenceCenter.longitude, la2: PatientLocation.latitude, lo2: PatientLocation.longitude)
        
        if (Double(distance!) <= Double(geofenceRadius!)){
            print("inside")
            
            /*content.title = "Patient Location Update"
             content.body = "Patient is inside the monitored region"
             content.sound = UNNotificationSound.default
             
             let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
             let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
             UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)*/
            
            
        }else{
            
            print("outside")
            
            let parameteres = ["to":"cNonS6WBsgU:APA91bFVubkcV-CWubBYbOv7dspn0jfGh_6u2qnXlUuxv-zXvXhJJLFsceobLAmE7gbbboisBpoSH-nJSPMN8ec2N6-ll49G8mgFzuU0YNo1Rlca30EBJ7gappKRqaDmGwKXFm4Vo119"
                , "notification":
                    ["title": "Check this Mobile (title)",
                     "body": "Rich Notification testing (body)",
                     "mutable_content": true,
                     "sound": "Tri-tone"]
                ,"data": [
                    "url": "www.google.com",
                    "dl": "www.google.com"
                ]
                ] as [String : Any]
            
            guard let url = URL(string: "https://fcm.googleapis.com/fcm/send") else {return}
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameteres, options: []) else {return}
            
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("key=AAAAOgYG2iY:APA91bHW67_XV6Rnhnfid-Hv8WJT5IZLCSzM4jg6B6y_eb9mdjC_djcUEN2zw8ADdbeU-kK0s9tE63l-dD0JqkzblZU_BaqvmSqNl3bqAGkn668KBwa6fGRMS-o7vHd2XzlZu3jMnurt", forHTTPHeaderField: "Authorization")
            
            
            
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                
                
                if let error = error{
                    print("error is :")
                    print(error)
                }
                
                
                
                
                if let httpResponse = response as? HTTPURLResponse{
                    
                    
                    if httpResponse.statusCode == 200{
                        
                        if let data = data{
                            let dataString = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
                            print("Data : \(dataString)")
                        }
                        
                        
                    }
                    else{
                        print("error occured : \(httpResponse)")
                    }
                }
                
                
                
                }.resume()
            
            
            /*content.title = "Patient Location Update"
             content.body = "Patient is outside of the monitored region"
             content.sound = UNNotificationSound.default
             
             let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
             let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
             UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)*/
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
        let patientLocation = CLLocationCoordinate2D(latitude: plat!, longitude: plong!)
        
        let centerLat = (location.latitude + patientLocation.latitude) / 2
        let centerLong = (location.longitude + patientLocation.longitude) / 2
        
        print("lat is:\(centerLat)")
        
        let centerDistance = haversineDinstance(la1: patientLocation.latitude, lo1: patientLocation.longitude, la2: location.latitude, lo2: location.longitude)
        print("distance is:\(centerDistance)")
        let centerLocation = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLong)
        
        let region = MKCoordinateRegion(center: centerLocation, latitudinalMeters: geofenceRadius! + centerDistance + 2000, longitudinalMeters: geofenceRadius! + centerDistance + 2000)
        mapView.setRegion(region, animated: true)
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
            locationManager.startUpdatingLocation()
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
    
}


extension PatientInfoController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return
            MKOverlayRenderer()
        }
        circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer!.fillColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        circleRenderer!.strokeColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        circleRenderer!.lineWidth = 4
        circleRenderer!.alpha = 0.3
        return circleRenderer!
        
    }
}

extension PatientInfoController: CLLocationManagerDelegate {
    
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










