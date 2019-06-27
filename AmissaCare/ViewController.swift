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

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    let locationManager:CLLocationManager = CLLocationManager()
    let regionInMeters: Double = 8000
    
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    
    //var previousLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
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
            mapView.showsUserLocation = true
            
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = 20
            center.requestAuthorization(options: [.alert, .sound]) {(granted,error) in }
            
            let geoFenceRegion: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(35.3112,-80.74300), radius: 20, identifier: "Charlotte")

            
            content.title = "Location Update"
            content.body = "You have entered a new region!"
            content.sound = UNNotificationSound.default
            
            locationManager.startMonitoring(for: geoFenceRegion)
            print(locationManager.monitoredRegions)
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
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        }
    }
    
    func startTackingUserLocation() {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        //previousLocation = getCenterLocation(for: mapView)
    }
    
    /*func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }*/
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        centerViewOnUserLocation()
        let center = locations[0] as CLLocation
        let geoCoder = CLGeocoder()
        
        /*
        guard let previousLocation = self.previousLocation else { return }
         
         guard center.distance(from: previousLocation) > 20 else { return }
         self.previousLocation = center

         geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return }
         
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
         
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
         
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            let subLocality = placemark.subLocality ?? ""
         
            DispatchQueue.main.sync {
                self.addressLabel.text = " \(streetNumber) \(streetName) \(subLocality)"
            }
         }*/

        geoCoder.reverseGeocodeLocation(center, completionHandler: {(data,error) -> Void in
            let placeMarks = data as! [CLPlacemark]
            let loc: CLPlacemark = placeMarks[0]
            
            self.mapView.centerCoordinate = center.coordinate
            let city = loc.locality ?? ""
            let streetNumber = loc.subThoroughfare ?? ""
            let streetName = loc.thoroughfare ?? ""
            let subLocality = loc.subLocality ?? ""
            self.addressLabel.text = "\(streetNumber) \(streetName) \(subLocality),\(city)"
            
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






