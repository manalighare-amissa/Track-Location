//
//  PatientList.swift
//  AmissaCare
//
//  Created by Manali Ghare on 7/29/19.
//  Copyright © 2019 Manali Ghare. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class PatientListController: UIViewController {
    
    
    @IBOutlet weak var patientListTableView: UITableView!
    @IBOutlet weak var addPatientButton: UIButton!
    
    var patientData = [String] ()
    var patientNames = [String] ()
    
    var selectedPatientName: String?
    var selectedPatientID: String?
    
    var patientRef: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        patientRef = Database.database().reference()
        loadPatientList()
        
    }
    
    func loadPatientList(){
        guard let userID = Auth.auth().currentUser?.uid
            else { return }
        
        patientRef?.child(userID).child("Patients").observe(.value, with: { (DataSnapshot) in
            let snapshot = DataSnapshot.value as? NSDictionary

    
            for key in snapshot!.allKeys{
                self.patientNames.append("\(snapshot![key]!)")
                self.patientData.append("\(key)")
                self.patientListTableView.reloadData()

            }
            
        })
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PatientListToMapViewSegue"{
            let PatientInfoController = segue.destination as! PatientLocationAndInfoController
            PatientInfoController.PatientName = selectedPatientName
            PatientInfoController.patientID = selectedPatientID
        }
    }
}



extension PatientListController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(patientData[indexPath.row])
        
        self.selectedPatientID = patientData[indexPath.row]
        self.selectedPatientName = patientNames[indexPath.row]
        
        self.performSegue(withIdentifier: "PatientListToMapViewSegue", sender: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}

extension PatientListController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.patientNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UITableViewCell
        cell.textLabel?.text = patientNames[indexPath.row]
        return cell
    }
    
    
    
}

