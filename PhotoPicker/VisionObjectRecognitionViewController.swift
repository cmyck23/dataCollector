/*
See LICENSE folder for this sample’s licensing information.
Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision
import FirebaseDatabase
import CoreMotion
import CoreLocation
import CoreMedia
import CoreVideo
import FirebaseStorage
import CSV
import Foundation
import SwiftyJSON
import MapKit
import Firebase

class VisionObjectRecognitionViewController: ViewControllerML, CLLocationManagerDelegate {
    
    var database = Database.database().reference()
    var motionManager = CMMotionManager()
    
    let firestoreDatabase = Firestore.firestore()
    
    // Used to start getting the users location
    let locationManager = CLLocationManager()
    
    // This is used to get the cities names from locations.
    let manager = CLLocation()
    var completion: ((CLLocation)-> Void)?
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            //print(topLabelObservation)
            
            // addNewEntry()
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            print(topLabelObservation.identifier)
            print(topLabelObservation.confidence)
            addNewEntry(typeOfDefect: String(topLabelObservation.identifier))
            
            shapeLayer.addSublayer(textLayer)
            //print(shapeLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        
        // Update firebase when a new object is detected
        //addNewEntry()
        return shapeLayer
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
    

    @objc public func addNewEntry(typeOfDefect: String)
   {
        
        
    let fibonnaci1 = 1.0
    let fibonnaci3 = 3.0
    let fibonnaci8 = 8.0
    let costMinorCrack = 2.5
    let costMajorCrack = 10.0
    let costPothole = 47.0
    let timeMinorCrack = 5.0
    let timeMajorCrack = 10.0
    let timePothole = 30.0
    let procedureMinorCrack = "Sealing"
    let procedureMajorCrack = "Manual patching and manual shovels"
    let procedurePothole = "Pothole repair"
    let equipmentMinorCrack = "Routed or non-routed crack sealing truck"
    let equipmentMajorCrack = "Pestles used for compaction"
    let equipmentPothole = "specialized equipment specifically made for pothole repair interventions"
        
        
    var location_Name = "Unknown"
        
        //--This is to create a date object to display the time later.
        print("-------------------------")
        print(typeOfDefect)
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
        
        print(LocationManager.shared.getUserLocation)
            
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
                    
                    print(locationName as Any)
                
                    self!.firestoreDatabase.collection("Areas").document(location_Name).getDocument{(document, error) in
                        
                        if error == nil{
                            
                            // Add and update information for existing area
                            if document != nil && document!.exists{
                                
                            
                                if locationName != "Unknown" {
                                    
                                    
                                    self!.firestoreDatabase.collection("Areas").document(location_Name).setData([
                                    "Last Updated":formatter1.string(from: today)
                                    ],merge: true)
                                
                                    let incrementer: Double = 1

                                    if typeOfDefect == "Minor_crack"{
                                    self!.firestoreDatabase.collection("Areas").document(location_Name).updateData([
                                            "Minor Cracks Number" : FieldValue.increment(incrementer),
                                            "Repair Cost" :FieldValue.increment(costMinorCrack),
                                        "Priority":FieldValue.increment(fibonnaci1),
                                        "Repair Time" : FieldValue.increment(timeMinorCrack),
                                        "Procedure 1" :procedureMinorCrack,
                                        "Equipment 1" :equipmentMinorCrack
                                        
                                        ])
                                    }
                                    else if typeOfDefect == "Major_crack"
                                    {
                                        self!.firestoreDatabase.collection("Areas").document(location_Name).updateData([
                                            "Major Cracks Number" : FieldValue.increment(incrementer),
                                            "Repair Cost" :FieldValue.increment(costMajorCrack),
                                            "Priority":FieldValue.increment(fibonnaci3),
                                            "Repair Time" : FieldValue.increment(timeMajorCrack),
                                            "Procedure 2" :procedureMajorCrack,
                                            "Equipment 2" :equipmentMajorCrack
                                            
                                            ])
                                    }
                                    else if typeOfDefect == "Pothole" {
                                            self!.firestoreDatabase.collection("Areas").document(location_Name).updateData([
                                                "Potholes Number" : FieldValue.increment(incrementer),
                                                "Repair Cost" : FieldValue.increment(costPothole),
                                                "Priority":FieldValue.increment(fibonnaci8),
                                                "Repair Time" : FieldValue.increment(timePothole),
                                                "Procedure 3" :procedurePothole,
                                                "Equipment 3" :equipmentPothole
                                            ])
                                    }
                                    self!.firestoreDatabase.collection("Areas").document(location_Name).updateData([
                                            "Total Defects" : FieldValue.increment(incrementer)
                                        ])
                                }
                                
                            }
                            
                            
                            // Add and create information for new area
                            else
                            {
                                
                                if locationName != "Unknown" {
                                self!.firestoreDatabase.collection("Areas").document(location_Name).setData(["name":location_Name,
                                "latitude":user_lat,
                                "longitude":user_long,
                                "Last Updated":formatter1.string(from: today),
                                "Road Type":"Asphalt/Concrete",
                                "Project's Manager":"Not yet chosen",
                                "Project's Supplier":"Not yet chosen"
                                ],merge: true)
                                    
                                
                                    
                                    if typeOfDefect == "Minor_crack"{
                                        self!.firestoreDatabase.collection("Areas").document(location_Name).setData([
                                        "Major Cracks Number":1,"Minor Cracks Number":1,"Potholes Number":0,"Total Defects":1,
                                            "Repair Time":timeMinorCrack,
                                            "Repair Cost":costMinorCrack,
                                            "Procedure 1" :procedureMinorCrack,
                                            "Equipment 1" :equipmentMinorCrack,
                                            "Priority": fibonnaci1]
                                        ,merge: true)
                                    }
                                    else if typeOfDefect == "Major_crack"
                                    {
                                        self!.firestoreDatabase.collection("Areas").document(location_Name).setData([
                                        "Major Cracks Number":1,"Minor Cracks Number":0,"Potholes Number":0,"Total Defects":1,
                                                "Repair Time":timeMajorCrack,
                                                "Repair Cost":costMajorCrack,
                                                "Procedure 2" :procedureMajorCrack,
                                                "Equipment 2" :equipmentMajorCrack,
                                                "Priority": fibonnaci3]
                                        ,merge: true)
                                    }
                                    else if typeOfDefect == "Pothole" {
                                        self!.firestoreDatabase.collection("Areas").document(location_Name).setData([
                                        "Major Cracks Number":0,"Minor Cracks Number":0,"Potholes Number":1,"Total Defects":1,
                                                "Repair Time":timePothole,
                                                "Repair Cost":costPothole,
                                                "Procedure 3" :procedurePothole,
                                                "Equipment 3" :equipmentPothole,
                                                "Priority": fibonnaci8]
                                        ,merge: true)
                                    }
                                }
                            }
                    }
                   }
                }
            }
    

    


        
//    database.child("Areas").child(location_Name).observeSingleEvent(of: .value, with: { (snapshot) in
//      // Get user value
//
//
//        let  totalNumberDefects = "8"
//        let object: [String : Any] = [
//            "Name": location_Name,
//            "City": "Unknown",
//            "Latitude" : user_lat ,
//            "Longitude" : user_long,
//            "Road Type" : roadTypes.randomElement()!,
//            "Day" : formatter1.string(from: today),
//            "Pothole Detected" : detection.randomElement()!,
//            "Potholes Number" : Int.random(in: 0..<10),
//            "Major Cracks Detected" : detection.randomElement()!,
//            "Major Cracks Number" : Int.random(in: 0..<10),
//            "Minor Cracks Detected" : detection.randomElement()!,
//            "Minor Cracks Number" : Int.random(in: 0..<10),
//            "Total Defects" : totalNumberDefects,
//            "Priority" : Float.random(in: 0..<5),
//            "Time Estimated To Fix": "",
//            "Cost Estimated To Fix": "",
//            "Equipment Required" :"Tools",
//            "Comments": "None",
//            "Project's Manager": "Not yet chosen",
//            "Poject's Suppliers": "Not yet chosen"
//        ]
//
//         self.database.child("AreasNames").observeSingleEvent(of: .value, with: { [self]snapshot in guard (snapshot.value as? [String: Any]) != nil
//        else{
//            database.child("AreasNames").child(location_Name).setValue(location_Name)
//            return
//        }
//        database.child("AreasNames").child(location_Name).setValue(location_Name)
//
//        })
//
//         self.database.child("Areas").observeSingleEvent(of: .value, with: { [self]snapshot in guard (snapshot.value as? [String: Any]) != nil
//        else{
//            database.child("Areas").child(location_Name).setValue(object)
//            return
//        }
//        database.child("Areas").child(location_Name).setValue(object)
//
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["name":location_Name])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["latitude":user_lat])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["longitude":user_long])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Last Day":formatter1.string(from: today)])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Priority":"Not yet calculated"])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Major Cracks Number":0])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Minor Cracks Number":0])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Potholes Number":0])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Road Type":"Asphalt/Concrete"])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Project's Manager":"Not yet chosen"])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Project's Supplier":"Not yet chosen"])
//         firestoreDatabase.collection("Areas").document(location_Name).setData(["Total Defects":totalNumberDefects])
//
//        })
//
//      }) { (error) in
//        print(error.localizedDescription)
//    }
    
            
   }

   }
