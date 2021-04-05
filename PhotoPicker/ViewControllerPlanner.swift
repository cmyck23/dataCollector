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

class ViewControllerPlanner: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var numberOfLocationsAnalyzed = 0
    var areaList = [String]()
    @IBOutlet var tableView: UITableView!
    var database = Database.database().reference()
    var databaseRef: DatabaseReference?
    var databaseHandle:DatabaseHandle?
    var names = ""
    let firestoreDatabase = Firestore.firestore()
    
    var filteredData: [String]!
    
    var numberOfRows = 0
    
    var initialLoadding = true
    
    var infoLocation = ""
    
    public var allLocationsWithInfo:[Dictionary<String, AnyObject>] =  Array()


    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        

        
        // Getting the records from firebase firestore
        firestoreDatabase.collection("Areas").order(by: "Priority",descending: true)
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
                
                
                self.filteredData = self.areaList
                self.numberOfRows = self.filteredData.count
                
            }
    
                print(self.areaList)
        
        // Do any additional setup after loading the view.
        
        
    }
    
    @IBAction func saveButton(_ sender: Any)
    {
    generateTextFile()
        
        if !allLocationsWithInfo.isEmpty{
            let alert = UIAlertController(title:"'MainPlanner.csv' File Created!",
                                          message: "You can find your file in your 'Road Analyzer' folder on your iPhone ",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok",
                                          style: .default,
                                          handler: {_ in
                                            
                                            
            }))
            
            self.present(alert, animated: true)
        }
        
    }
    
    //This function is executed when a row is being clicked. !
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "DetailedPlannerViewController")
        as? DetailedPlannerViewController
        
//        print("Type of indexPath")
//        print(type(of: indexPath.row))
        var select = ""
        
        if initialLoadding == true {
            select = String(areaList[indexPath.row])
        }
        else
        {
            select = String(filteredData[indexPath.row])
        }
        
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
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("you tapped me in list view!\(indexPath.row)")
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Here we return the number of rows equal to the number of elements in the array
        print("Number of rows")
        print(self.numberOfRows)
        
        if initialLoadding == true {
            return self.areaList.count
        }
        else
        {
            return self.filteredData.count
        }
    
    }
    
    // This function will create each cell from the list fetched from firebase.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        
        //Connect each cell to the table view to the cell with identifier "cell".
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        
        if initialLoadding == true {
            cell.textLabel?.text = areaList[indexPath.row]
        }
        else {
            cell.textLabel?.text = filteredData[indexPath.row]
        }
        
        cell.textLabel?.textColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        // We want to return the cell to fill the table view.
        return cell
    }
    
    // Set the search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = []
        
        if searchText == ""
        {
            initialLoadding = true
           filteredData = areaList
            print("Inside searchBarFunction")
            
            // Dismiss keyboard when field is emptied
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
        }
        else{
        for locations in areaList {
            initialLoadding = false
            if locations.lowercased().contains(searchText.lowercased()){
                filteredData.append(locations)
            }
            self.numberOfRows = self.filteredData.count
        }
        }
        
        self.tableView.reloadData()
    }
    

    func generateTextFile()
    {
        self.infoLocation = ""
        var dct = Dictionary<String, AnyObject>()
        
        for locations in areaList {
        
        let docRef = self.firestoreDatabase.collection("Areas").document(locations)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                
                let nameLoc = document.get("name") as? String
                dct.updateValue(nameLoc as AnyObject, forKey: "Name")
                self.infoLocation.append(nameLoc ?? "Unknown")
                
                self.infoLocation.append(",")
                
                
                let lastUpdated = document.get("Last Updated") as? String
                dct.updateValue(lastUpdated as AnyObject, forKey: "LastUpdated")
                self.infoLocation.append(lastUpdated ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let repairCost = document.get("Repair Cost") as? Float
                dct.updateValue(repairCost as AnyObject, forKey: "RepairCost")
                self.infoLocation.append(String(repairCost ?? 0))
                self.infoLocation.append(",")
                
                
                let repairTime = document.get("Repair Time") as? Float
                dct.updateValue(repairTime as AnyObject, forKey: "RepairTime")
                self.infoLocation.append(String(repairTime ?? 0))
                self.infoLocation.append(",")
                
                
                let latitude = document.get("latitude") as? String
                dct.updateValue(latitude as AnyObject, forKey: "Latitude")
                self.infoLocation.append(latitude ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let longitude = document.get("longitude") as? String
                dct.updateValue(longitude as AnyObject, forKey: "Longitude")
                
                self.infoLocation.append(longitude ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let projectManager = document.get("Project's Manager") as? String
                dct.updateValue(projectManager as AnyObject, forKey: "Manager")
                self.infoLocation.append(projectManager ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let projectSupplier = document.get("Project's Supplier") as? String
                dct.updateValue(projectSupplier as AnyObject, forKey: "Supplier")
                self.infoLocation.append(projectSupplier ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let totalDefects = document.get("Total Defects") as? Float
                dct.updateValue(totalDefects as AnyObject, forKey: "TotalDefects")
                self.infoLocation.append(String(totalDefects ?? 0))
                self.infoLocation.append(",")
                
                
                let roadType = document.get("Road Type") as? String
                dct.updateValue(roadType as AnyObject, forKey: "RoadType")
                self.infoLocation.append(roadType ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let potholesNumber = document.get("Potholes Number") as? Float
                dct.updateValue(potholesNumber as AnyObject, forKey: "PotholesNumber")
                self.infoLocation.append(String(potholesNumber ?? 0))
                self.infoLocation.append(",")
                
                
                let minorCracks = document.get("Minor Cracks Number") as? Float
                dct.updateValue(minorCracks as AnyObject, forKey: "MinorCracks")
                self.infoLocation.append(String(minorCracks ?? 0))
                self.infoLocation.append(",")
                
                
                let majorCracks = document.get("Major Cracks Number") as? Float
                dct.updateValue(majorCracks as AnyObject, forKey: "MajorCracks")
                self.infoLocation.append(String(majorCracks ?? 0))
                self.infoLocation.append(",")
               
                
                let priority = document.get("Priority") as? Float
                dct.updateValue(priority as AnyObject, forKey: "Priority")
                self.infoLocation.append(String(priority ?? 0))
                self.infoLocation.append(",")
                
                
                let procedure1 = document.get("Procedure 1") as? String
                dct.updateValue(procedure1 as AnyObject, forKey: "Procedure1")
                let procedure2 = document.get("Procedure 2") as? String
                dct.updateValue(procedure2 as AnyObject, forKey: "Procedure2")
                let procedure3 = document.get("Procedure 3") as? String
                dct.updateValue(procedure3 as AnyObject, forKey: "Procedure3")
                
                self.infoLocation.append(procedure1 ?? "")
                
                self.infoLocation.append(procedure2 ?? "")
                
                self.infoLocation.append(procedure3 ?? "")
                self.infoLocation.append(",")
                
                                
                let equipment1 = document.get("Equipment 1") as? String
                dct.updateValue(equipment1 as AnyObject, forKey: "Equipment1")
                let equipment2 = document.get("Equipment 2") as? String
                dct.updateValue(equipment2 as AnyObject, forKey: "Equipment2")
                let equipment3 = document.get("Equipment 3") as? String
                dct.updateValue(equipment3 as AnyObject, forKey: "Equipment3")
                
                self.infoLocation.append(equipment1 ?? "")
                
                self.infoLocation.append(equipment2 ?? "")
                
                self.infoLocation.append(equipment3 ?? "")
                self.infoLocation.append(",")
                
                let Address = document.get("name") as? String
                self.infoLocation.append(Address ?? "")
                self.infoLocation.append("\n")
                
                
                // Do any additional setup after loading the view
                self.allLocationsWithInfo.append(dct)
            
            } else {
                
                print("Document does not exist")
            }
        }
    }
        
        
        //print(self.allLocationsWithInfo)
        
        createCSV(from: self.allLocationsWithInfo)
    }
    
    func createCSV(from recArray:[Dictionary<String, AnyObject>]) {
        

            var csvString = "\("Name"),\("LastUpdated"),\("RepairCost"),\("RepairTime"),\("Latitude"),\("Longitude"),\("Manager"),\("Supplier"),\("TotalDefects"),\("RoadType"),\("PotholesNumber"),\("MinorCracks"),\("MajorCracks"),\("Priority"),\("Procedure1"),\("Procedure2"),\("Procedure3"),\("Equipment1"),\("Equipment2"),\("Equipment3")\n"
        
            for dct in recArray {
                csvString = csvString.appending("\(String(describing: dct["Name"]!)),\(String(describing: dct["LastUpdated"]!)),\(String(describing: dct["RepairCost"]!)),\(String(describing: dct["RepairTime"]!)),\(String(describing: dct["Latitude"]!)),\(String(describing: dct["Longitude"]!)),\(String(describing: dct["Manager"]!)),\(String(describing: dct["Supplier"]!)),\(String(describing: dct["TotalDefects"]!)),\(String(describing: dct["RoadType"]!)),\(String(describing: dct["PotholesNumber"]!)),\(String(describing: dct["MinorCracks"]!)),\(String(describing: dct["MajorCracks"]!)),\(String(describing: dct["Priority"]!)),\(String(describing: dct["Procedure1"]!)),\(String(describing: dct["Procedure2"]!)),\(String(describing: dct["Procedure3"]!)),\(String(describing: dct["Equipment1"]!)),\(String(describing: dct["Equipment2"]!)),\(String(describing: dct["Equipment3"]!))\n")
            }

            //let fileManager = FileManager.default
        
            //let file = "\(UUID().uuidString).csv"
            let file = "MainPlanner.csv"
        
            do {
//                let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                
                
                let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = dir.appendingPathComponent(file)
                
                try csvString.write(to: fileURL, atomically: false, encoding: .utf8)
                
                
                
            } catch {
                print("error creating file")
            }
        
        }
    
   
    
    
}


