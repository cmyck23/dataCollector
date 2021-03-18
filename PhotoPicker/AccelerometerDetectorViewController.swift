//
//  AccelerometerDetectorViewController.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-03-17.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import Firebase

class AccelerometerDetectorViewController: UIViewController {

    let firestoreDatabase = Firestore.firestore()
    
    
    
    @IBOutlet var text: UITextView!
    var motionManager = CMMotionManager()
    // Used to start getting the users location
    let locationManager = CLLocationManager()
    public var csvArray:[Dictionary<String, AnyObject>] =  Array()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
        
        showIRI()
    }
    
    func showIRI(){
        
        self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let myData = data
            {
                //--This is to create a date object to display the time later.
                print("Inside Accelerometer Detector")
                print("-------------------------")
                let currentDateTime = Date()
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                formatter.dateStyle = .long
                let dateTimeString = formatter.string(from: currentDateTime)
                
            
                //-Print time
                print (dateTimeString)
                
                print ("Displaying latitude and longitude (GPS DATA)")
                
                //Get current latitude and save it as a string.
                let user_lat = String(format: "%f", self.locationManager.location!.coordinate.latitude)
                //Get current longitude and save it as a string.
                let user_long = String(format: "%f", self.locationManager.location!.coordinate.longitude)
                
                print(user_lat)
                print(user_long)
                    
                print ("Displaying accelerometer data")
                
                //Convert longitudes and latitudes to string.

                let user_accelerometerXValue = String(format: "%f", myData.acceleration.x)
                let user_accelerometerYValue = String(format: "%f", myData.acceleration.y)
                let user_accelerometerZValue = String(format: "%f", myData.acceleration.z)
                
                print(type(of: myData.acceleration.z))
                
                
                print( user_accelerometerXValue)
                print( user_accelerometerYValue)
                print( user_accelerometerZValue)
                
                var speed = self.locationManager.location!.speed*3.6
                
                let averageZValue = -0.02960339
                
                var roughnessIndex = 0.0
                
                speed = 70
                
                if speed <= 0
                {
                    speed = 0
                    roughnessIndex = 0
                    print(roughnessIndex)
                    self.text.text = ("No Defect Detected : "+String(roughnessIndex))
                }
                else
                {
                    roughnessIndex = (sqrt(pow(myData.acceleration.z-averageZValue,2))/speed)*100
                    print(roughnessIndex)
                    if (roughnessIndex > 1.5)
                    {
                        self.text.textColor = UIColor.red
                        self.text.text = ("Potential Defect Detected : "+String(roughnessIndex))
                        self.addNewEntry()
                    }
                    else{
                        self.text.textColor = UIColor.green
                        self.text.text = ("No Defect Detected : "+String(roughnessIndex))
                    }
                    
                    
                }
                
                print("Displaying Speed")
                //--Displaying speed of the motion of the phone in kilometer per hour.
                print(speed)
            
                print("RougnessIndex"+String(roughnessIndex))
                
            }
            
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
    
    
    @objc public func addNewEntry()
   {
    
    var location_Name = "Unknown"
        
        //--This is to create a date object to display the time later.
        print("-------------------------")
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .long
    _ = formatter.string(from: currentDateTime)
        
        //Get current latitude and save it as a string.
        let user_lat = String(format: "%f", self.locationManager.location!.coordinate.latitude)
        //Get current longitude and save it as a string.
        let user_long = String(format: "%f", self.locationManager.location!.coordinate.longitude)
    
    var speed = self.locationManager.location!.speed*3.6
    
    if speed <= 0
    {
        speed = 0
    }

//   let roadTypes = ["Asphalt", "Concrete", "Earth", "Stones"]
//   let detection = ["YES","NO"]
   let today = Date()
   let formatter1 = DateFormatter()
   formatter1.dateStyle = .short
            
            LocationManager.shared.getUserLocation{[weak self]location in
                
                DispatchQueue.main.async {
                    guard self != nil else
                    {
                        return
                    }
                }
                
                location_Name=LocationManager.shared.resolveLocationName(with: location){ [self]
                    locationName in self!.title = locationName
                    location_Name = locationName ?? "Unknown"
                    
                    print(locationName ?? "Unknown")
                
                    self!.firestoreDatabase.collection("AreasAccelerometer").document(location_Name).getDocument{(document, error) in
                        
                        if error == nil{
                            
                            if document != nil && document!.exists{
                                
                            
                                if locationName != "Unknown" {
                                    let incrementer: Double = 1

                                    self!.firestoreDatabase.collection("AreasAccelerometer").document(location_Name).updateData([
                                            "Total Defects" : FieldValue.increment(incrementer)
                                        ])
                                }
                                
                            }
                            
                            else
                            {
                                
                                if locationName != "Unknown" {
                                self!.firestoreDatabase.collection("AreasAccelerometer").document(location_Name).setData(["name":location_Name,
                                "latitude":user_lat,
                                "longitude":user_long,
                                "Last Update":formatter1.string(from: today)],merge: true)
                                    
                                let incrementer: Double = 1
                                self!.firestoreDatabase.collection("AreasAccelerometer").document(location_Name).updateData([
                                "Total Defects" : FieldValue.increment(incrementer)])
                                    
                                    }
                                }
                            }
                    }
                   }
                }

}
    }

