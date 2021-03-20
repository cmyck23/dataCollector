//
//  ViewControllerAccelerometerList.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-03-20.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class ViewControllerAccelerometerList: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var numberOfLocationsAnalyzed = 0
    var areaList = [String]()
    @IBOutlet var tableView: UITableView!
    
    
    
    var database = Database.database().reference()
    var databaseRef: DatabaseReference?
    var databaseHandle:DatabaseHandle?
    var names = ""
    let firestoreDatabase = Firestore.firestore()


    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Getting the records from firebase firestore
        firestoreDatabase.collection("AreasAccelerometer").addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let places = documents.map {$0["name"]!}
                
                for row in places{
                    self.areaList.append(row as! String)
                    self.tableView.reloadData()
                }
                
                print("Locations Found: \(places)")
            }
        
        print("Trying to print areaList")
        print(areaList)
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "DetailedPlannerAccelerometerViewController")
        as? DetailedPlannerAccelerometerViewController
        
//        print("Type of indexPath")
//        print(type(of: indexPath.row))
        var select = ""
        print("Inside the table view fucntion")
        select = String(areaList[indexPath.row])
        
        print(select)
        
        let docRef = self.firestoreDatabase.collection("AreasAccelerometer").document(select)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                

                let dataDescription = document.data().map(String.init(describing:)) ?? "No Data Found"
                
                
                let Address = document.get("name") as? String


                print(type(of: dataDescription))
                
                var sentence = dataDescription.replacingOccurrences(of: ",", with: "\n")
                sentence = sentence.replacingOccurrences(of: "[", with: " ")
                sentence = sentence.replacingOccurrences(of: "]", with: "")
                sentence = sentence.replacingOccurrences(of: "\"", with: "")
                sentence = sentence.replacingOccurrences(of: "\\", with: "")
                
                vc?.name = " Address : "+Address!+"\n"+sentence
                self.navigationController?.pushViewController(vc!, animated: true)

            } else {
                vc?.name = String("No Data Found")
                self.navigationController?.pushViewController(vc!, animated: true)
                print("Document does not exist")
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("you tapped me in list view!\(indexPath.row)")
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.areaList.count
    
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cellAccelerometer = tableView.dequeueReusableCell(withIdentifier: "cellAccelerometer", for: indexPath)
        cellAccelerometer.textLabel?.text = areaList[indexPath.row]
        return cellAccelerometer
    }

}


   
