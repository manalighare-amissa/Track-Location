//
//  BarcodeScannerController.swift
//  AmissaCare
//
//  Created by Manali Ghare on 7/29/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabase

class BarcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    
    @IBOutlet var superView: UIView!
    @IBOutlet weak var barcodeScanSquare: UIImageView!
    var video = AVCaptureVideoPreviewLayer()
    
    var patientRef: DatabaseReference!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        patientRef = Database.database().reference()
        
       
        let session = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("Failed to get the camera device")
            return
            
        }
        do{
            let input = try AVCaptureDeviceInput(device: captureDevice)
            session.addInput(input)
        }
        catch{
            print("ERROR")
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        video = AVCaptureVideoPreviewLayer(session: session)
        video.frame = view.layer.bounds
        view.layer.addSublayer(video)
        
        self.view.bringSubviewToFront(barcodeScanSquare)
        
        session.startRunning()
       
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        
        
        if metadataObjects != nil && metadataObjects.count != 0
        {
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject
            {
                if object.type == AVMetadataObject.ObjectType.qr
                {
                  
                    let alert = UIAlertController(title: "Add Name", message: nil, preferredStyle: .alert)
                    
                    alert.addTextField { (TextField) in
                        TextField.placeholder = "Enter name of the patient"
                        TextField.autocapitalizationType = .sentences
                    }
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert](_) in
                        
                        guard let userID = Auth.auth().currentUser?.uid
                            else { return }
                        
                        self.patientRef.child("\(userID)").child("Patients").child("\(object.stringValue!)").setValue(alert?.textFields![0].text)
                        
                        self.performSegue(withIdentifier: "BackToPatientListSegue", sender: nil)
                        
                    }))
                    
                    superView.alpha = 0.2
                    present(alert,animated: true,completion: nil)
                
                  
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    

}
