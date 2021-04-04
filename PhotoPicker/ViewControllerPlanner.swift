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


    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        

        
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
                
                
                self.filteredData = self.areaList
                self.numberOfRows = self.filteredData.count
                
            }
    
                print(self.areaList)
        
        // Do any additional setup after loading the view.
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
}
