//
//  ViewControllerPlanner.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-02-27.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewControllerPlanner: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var numberOfLocationsAnalyzed = 0
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("you tapped me in list view!")
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
      
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "hello"
        return cell
    }
    
    @IBOutlet var tableView: UITableView!
       
    
    private let database = Database.database().reference()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Keep this functiom
        //Not neededed at the current time
        //displayButtonToGenerateValue()
        //retrieveAllAreaNames()
        
        tableView.delegate = self
        tableView.dataSource = self
            

       
        // Do any additional setup after loading the view.
    }
    

    private func retrieveAllAreaNames() -> Int
    {
        //var i = 0
        var numOfRows: Int = 0
        let ref = database.child("Areas")
        ref.observeSingleEvent(of: .value, with: {
            snapshot in guard let value = snapshot.value as? [String: Any]
        else
            {
            return
            }
        //print("Value: \(value.count)")
        print("Try to print children count")

        print(value.keys)
        numOfRows = numOfRows + 1
        print("inside function_\(numOfRows)")
        })

        print("outside function_\(numOfRows)")
        return numOfRows
        
    }
    
    
    private func displayButtonToGenerateValue()
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
    
    
    
    @objc private func addNewEntry()
    {
        let citiesNames = ["Montreal", "Quebec City", "Toronto", "Laval"]
        let roadTypes = ["Asphalt", "Concrete", "Earth", "Stones"]
        let detection = ["YES","NO"]
        let today = Date()
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        
        //print(formatter1.string(from: today))

        let object: [String : Any] = [
            "Name": "Location_\(Int.random(in: 0..<100))",
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
        
        
        
        database.child("Areas").observeSingleEvent(of: .value, with: { [self]snapshot in guard let value = snapshot.value as? [String: Any]
        else{
            database.child("Areas").child("Area_\(1)").setValue(object)
            return
            
        }
        numberOfLocationsAnalyzed = value.count
        numberOfLocationsAnalyzed+=1
        database.child("Areas").child("Area_\(numberOfLocationsAnalyzed)").setValue(object)
        print("Value: \(value.count)")
        })
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
