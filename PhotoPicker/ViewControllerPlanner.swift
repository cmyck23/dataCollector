//
//  ViewControllerPlanner.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-02-27.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class ViewControllerPlanner: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
        firestoreDatabase.collection("Areas")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let places = documents.map {$0["name"]}
                
                for row in places{
                    
                    if row != nil{
                    self.areaList.append(row as! String)
                        print(row as Any)
                        self.tableView.reloadData()
                    }
                }
                
                print("Locations Found: \(places)")
            }
        
        print(self.areaList)
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "DetailedPlannerViewController")
        as? DetailedPlannerViewController
        
//        print("Type of indexPath")
//        print(type(of: indexPath.row))
        var select = ""
        select = String(areaList[indexPath.row])
        
        let docRef = self.firestoreDatabase.collection("Areas").document(select)
        

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
            
                let dataDescription = document.data().map(String.init(describing:)) ?? "No Data Found"
                
                let name = document.get("name") as? String
                
                print(type(of: dataDescription))
                
                vc?.name = name!
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
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = areaList[indexPath.row]
        cell.textLabel?.textColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        return cell
    }

}
