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

class ViewControllerAccelerometerList: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var numberOfLocationsAnalyzed = 0
    var areaList = [String]()
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    var database = Database.database().reference()
    var databaseRef: DatabaseReference?
    var databaseHandle:DatabaseHandle?
    var names = ""
    let firestoreDatabase = Firestore.firestore()
    
    public var allLocationsWithInfo:[Dictionary<String, AnyObject>] =  Array()
    
    
    
    var infoLocation = ""
    var filteredData: [String]!
    
    var numberOfRows = 0
    
    var initialLoadding = true
    
    //var MainTabBarController: UITabBarController


    
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
        
        let alert = UIAlertController(title:"Welcome to the Planner from IRI Analysis",
                                      message: "You can search for any location ",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok",
                                      style: .default,
                                      handler: {_ in
                                        
                                        
        }))
        
        self.present(alert, animated: true)
        
        searchBar.delegate = self
        
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
                    //print("Observe appending : ")
                    //print(row as! String)
                    self.tableView.reloadData()
                }
                
                //print("Locations Found: \(places)")
            
            self.filteredData = self.areaList
            self.numberOfRows = self.filteredData.count
            
            }
        
        //print("Trying to print areaList")
        //print(areaList)
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func saveButton(_ sender: Any)
    {
    generateTextFile()
        
        if !allLocationsWithInfo.isEmpty{
            let alert = UIAlertController(title:"'AccelerometerPlanner.csv' File Created!",
                                          message: "You can find your file in your 'Road Analyzer' folder on your iPhone ",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok",
                                          style: .default,
                                          handler: {_ in
                                            
                                            
            }))
            
            self.present(alert, animated: true)
        }
        else
        {
            let alert = UIAlertController(title:"File Empty !",
                                          message: "Please try again !",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok",
                                          style: .default,
                                          handler: {_ in
                                            
                                            
            }))
            
            self.present(alert, animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(identifier: "DetailedPlannerAccelerometerViewController")
        as? DetailedPlannerAccelerometerViewController
        
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
        
        //print(select)
        
        let docRef = self.firestoreDatabase.collection("AreasAccelerometer").document(select)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                _ = document.data().map(String.init(describing:)) ?? "No Data Found"
                
                let Address = document.get("name") as? String

                //print(type(of: dataDescription))
                
            
                
                vc?.name = Address!
                self.navigationController?.pushViewController(vc!, animated: true)

            } else {
                vc?.name = String("No Data Found")
                self.navigationController?.pushViewController(vc!, animated: true)
                print("Document does not exist")
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        //areaList.removeAll()
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("you tapped me in list view!\(indexPath.row)")
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //print(self.numberOfRows)
        
        if initialLoadding == true {
            return self.areaList.count
        }
        else
        {
            return self.filteredData.count
        }
    
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cellAccelerometer = tableView.dequeueReusableCell(withIdentifier: "cellAccelerometer", for: indexPath)
        if initialLoadding == true {
            cellAccelerometer.textLabel?.text = areaList[indexPath.row]
        }
        else {
            cellAccelerometer.textLabel?.text = filteredData[indexPath.row]
        }
        
        cellAccelerometer.textLabel?.textColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        cellAccelerometer.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        return cellAccelerometer
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = []
        
        if searchText == ""
        {
            initialLoadding = true
           filteredData = areaList
            //print("Inside searchBarFunction")
            
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
        
        let docRef = self.firestoreDatabase.collection("AreasAccelerometer").document(locations)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                
                let nameLoc = document.get("name") as? String
                dct.updateValue(nameLoc as AnyObject, forKey: "Name")
                self.infoLocation.append(nameLoc ?? "Unknown")
                self.infoLocation.append(",")
                
                let lastUpdated = document.get("Last Update") as? String
                dct.updateValue(lastUpdated as AnyObject, forKey: "LastUpdated")
                self.infoLocation.append(lastUpdated ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let latitude = document.get("latitude") as? String
                dct.updateValue(latitude as AnyObject, forKey: "Latitude")
                self.infoLocation.append(latitude ?? "Unknown")
                self.infoLocation.append(",")
                
                
                let longitude = document.get("longitude") as? String
                dct.updateValue(longitude as AnyObject, forKey: "Longitude")
                
                self.infoLocation.append(longitude ?? "Unknown")
                self.infoLocation.append(",")
                
            
                let totalDefects = document.get("Total Defects") as? Float
                dct.updateValue(totalDefects as AnyObject, forKey: "TotalDefects")
                self.infoLocation.append(String(totalDefects ?? 0))
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
        

            var csvString = "\("Name"),\("LastUpdated"),\("Latitude"),\("Longitude"),\("TotalDefects")\n"
        
            for dct in recArray {
                csvString = csvString.appending("\(String(describing: dct["Name"]!)),\(String(describing: dct["LastUpdated"]!)),\(String(describing: dct["Latitude"]!)),\(String(describing: dct["Longitude"]!)),\(String(describing: dct["TotalDefects"]!))\n")
            }

            //let fileManager = FileManager.default
        
            //let file = "\(UUID().uuidString).csv"
            let file = "AccelerometerPlanner.csv"
        
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


   
