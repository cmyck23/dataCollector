//
//  DetailedPlannerAccelerometerViewController.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-03-20.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseFirestore

class DetailedPlannerAccelerometerViewController: UIViewController {

    @IBOutlet weak var lbl: UITextView!
    

    let firestoreDatabase = Firestore.firestore()
    
    var name = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let docRef = self.firestoreDatabase.collection("AreasAccelerometer").document(name)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                
                _ = document.get("name") as? String
                self.name.append("\n\n")
                
                let lastUpdated = document.get("Last Update") as? String
                self.name.append("Last Updated : ")
                self.name.append(lastUpdated ?? "Unknown")
                self.name.append("\n")
                
                let latitude = document.get("latitude") as? String
                self.name.append("Latitude : ")
                self.name.append(latitude ?? "Unknown")
                self.name.append("\n")
                
                let longitude = document.get("longitude") as? String
                self.name.append("Longitude : ")
                self.name.append(longitude ?? "Unknown")
                self.name.append("\n")
                                
                let totalDefects = document.get("Total Defects") as? Float
                self.name.append("Total Number of Defects : ")
                self.name.append(String(totalDefects ?? 0))
                self.name.append("\n")
            
                let Address = document.get("name") as? String
                self.name.append("Address : ")
                self.name.append(Address ?? "")
                self.name.append("\n")
                
                // Do any additional setup after loading the view
                
                self.lbl.text = self.name
 
        
            } else {
                
                print("Document does not exist")
            }
        }
    }
    

}
