//
//  DetailedPlannerViewController.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-03-01.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseFirestore

class DetailedPlannerViewController: UIViewController {
    
    @IBOutlet weak var lbl: UITextView!
    let firestoreDatabase = Firestore.firestore()
    
    var name = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        let docRef = self.firestoreDatabase.collection("Areas").document(name)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                _ = document.get("name") as? String
                self.name.append("\n\n")
                
                let lastUpdated = document.get("Last Updated") as? String
                self.name.append("Last Day Updated : ")
                self.name.append(lastUpdated ?? "Unknown")
                self.name.append("\n")
                
                let repairCost = document.get("Repair Cost") as? Float
                self.name.append("Repair Cost : ")
                self.name.append(String(repairCost ?? 0))
                self.name.append("\n")
                
                let repairTime = document.get("Repair Time") as? Float
                self.name.append("Repair Time : ")
                self.name.append(String(repairTime ?? 0))
                self.name.append("\n")
                
                let latitude = document.get("latitude") as? String
                self.name.append("Latitude : ")
                self.name.append(latitude ?? "Unknown")
                self.name.append("\n")
                
                let longitude = document.get("longitude") as? String
                self.name.append("Longitude : ")
                self.name.append(longitude ?? "Unknown")
                self.name.append("\n")
                
                let projectManager = document.get("Project's Manager") as? String
                self.name.append("Project's Manager : ")
                self.name.append(projectManager ?? "Unknown")
                self.name.append("\n")
                
                let projectSupplier = document.get("Project's Supplier") as? String
                self.name.append("Project's Supplier : ")
                self.name.append(projectSupplier ?? "Unknown")
                self.name.append("\n")
                
                let totalDefects = document.get("Total Defects") as? Float
                self.name.append("Total Number of Defects : ")
                self.name.append(String(totalDefects ?? 0))
                self.name.append("\n")
                
                let roadType = document.get("Road Type") as? String
                self.name.append("Road Type : ")
                self.name.append(roadType ?? "Unknown")
                self.name.append("\n")
                
                let potholesNumber = document.get("Potholes Number") as? Float
                self.name.append("Potholes Number : ")
                self.name.append(String(potholesNumber ?? 0))
                self.name.append("\n")
                
                let minorCracks = document.get("Minor Cracks Number") as? Float
                self.name.append("Minor Cracks Number : ")
                self.name.append(String(minorCracks ?? 0))
                self.name.append("\n")
                
                let majorCracks = document.get("Major Cracks Number") as? Float
                self.name.append("Major Cracks Number : ")
                self.name.append(String(majorCracks ?? 0))
                self.name.append("\n")
                
                let priority = document.get("Priority") as? Float
                self.name.append("Priority : ")
                self.name.append(String(priority ?? 0))
                self.name.append("\n")
                
                let procedure1 = document.get("Procedure 1") as? String
                let procedure2 = document.get("Procedure 2") as? String
                let procedure3 = document.get("Procedure 3") as? String
                self.name.append("Procedure : ")
                self.name.append(procedure1 ?? "")
                self.name.append(" ")
                self.name.append(procedure2 ?? "")
                self.name.append(" ")
                self.name.append(procedure3 ?? "")
                self.name.append("\n")
                                
                let Equipment1 = document.get("Equipment 1") as? String
                let Equipment2 = document.get("Equipment 2") as? String
                let Equipment3 = document.get("Equipment 3") as? String
                self.name.append("Equipment Required : ")
                self.name.append(Equipment1 ?? "")
                self.name.append(" ")
                self.name.append(Equipment2 ?? "")
                self.name.append(" ")
                self.name.append(Equipment3 ?? "")
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
