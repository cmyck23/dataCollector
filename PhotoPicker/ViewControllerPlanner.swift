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
        
//        Keep this functiom
//        Not neededed at the current time
    //displayButtonToGenerateValue()
        
        databaseHandle = database.child("AreasNames").observe(.childAdded, with: {(snapshot) in
            let post = snapshot.value as? String
            if let actualPost = post{
                self.areaList.append(actualPost)
                self.tableView.reloadData()
            }
        })
        
        
        // Getting the records from firebase firestore
        firestoreDatabase.collection("Areas").whereField("Road Type", isEqualTo: "Asphalt/Concrete")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let places = documents.map {$0["name"]!}
                
                for row in places{
                    self.areaList.append(row as! String)
                    print(row)
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
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = areaList[indexPath.row]
        return cell
    }
    

     public func displayButtonToGenerateValue()
    {
        database.child("Area_38").observeSingleEvent(of: .value, with: {snapshot in guard let value = snapshot.value as? [String: Any]
        else{return
            
        }
        print("Value: \(value)")
        })
        
        //Create a button to generate a random area with entries
        let button = UIButton(frame: CGRect(x: 20, y: 200,width: view.frame.size.width-40 ,height: 50 ))
        button.setTitle("Generate Random Entry", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .link

        view.addSubview(button)
        button.addTarget(self, action: #selector(addNewEntry), for: .touchUpInside)
    }
    
    
    
    @objc public func addNewEntry()
    {
        let citiesNames = ["Montreal", "Quebec City", "Toronto", "Laval"]
        let roadTypes = ["Asphalt", "Concrete", "Earth", "Stones"]
        let detection = ["YES","NO"]
        let today = Date()
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        
        //print(formatter1.string(from: today))

        let nameRandLoc :String = "Location_\(Int.random(in: 0..<100))"
        
        
        let object: [String : Any] = [
            "Name": nameRandLoc,
            "City": citiesNames.randomElement()!,
            "Latitude" : Float.random(in: -180..<180),
            "Longitude" : Float.random(in: -90..<90),
            "Road Type" : roadTypes.randomElement()!,
            "Day" : formatter1.string(from: today),
            "Pothole Detected" : detection.randomElement()!,
            "Potholes Number" : Int.random(in: 0..<10),
            "Major Cracks Detected" : detection.randomElement()!,
            "Major Cracks Number" : Int.random(in: 0..<10),
            "Minor Cracks Detected" : detection.randomElement()!,
            "Minor Cracks Number" : Int.random(in: 0..<10),
            "Total Defects" : Int.random(in: 0..<10),
            "Priority" : Float.random(in: 0..<5),
            "Time Estimated To Fix": "",
            "Cost Estimated To Fix": "",
            "Equipment Required" :"Tools",
            "Comments": "None",
            "Project's Manager": "Not yet chosen",
            "Poject's Suppliers": "Not yet chosen"
        ]
        
        
        

        database.child("AreasNames").observeSingleEvent(of: .value, with: { [self]snapshot in guard (snapshot.value as? [String: Any]) != nil
        else{
            database.child("AreasNames").childByAutoId().setValue(nameRandLoc)
            return
        }
        database.child("AreasNames").childByAutoId().setValue(nameRandLoc)
       
        })
        
        database.child("Areas").observeSingleEvent(of: .value, with: { [self]snapshot in guard (snapshot.value as? [String: Any]) != nil
        else{
            database.child("Areas").child(nameRandLoc).setValue(object)
            return
        }
        database.child("Areas").child(nameRandLoc).setValue(object)
       
        })
    }
}
