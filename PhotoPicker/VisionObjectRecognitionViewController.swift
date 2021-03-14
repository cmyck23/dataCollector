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

class VisionObjectRecognitionViewController: ViewControllerML, CLLocationManagerDelegate {
    
    var database = Database.database().reference()
    var motionManager = CMMotionManager()
    
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
            print(topLabelObservation)
            
            // addNewEntry()
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            print(shapeLayer)
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
        addNewEntry()
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
    

   @objc public func addNewEntry()
   {

    self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
        if let myData = data
    {
    
            
        //--This is to create a date object to display the time later.
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
            

            LocationManager.shared.getUserLocation{[weak self]location in
                
                DispatchQueue.main.async {
                    guard self != nil else
                    {
                        return
                    }
                    print(location)
                }
                
                LocationManager.shared.resolveLocationName(with: location){
                    locationName in self?.title = locationName
                    
                    print(locationName as Any)
                }
            }
            
            
        print(user_lat)
        print(user_long)
            
            
        var cityName  = ""
        
            if user_lat.contains("45.50884") && user_long.contains("-73.58781")  {
                cityName = "Montreal"
            }
            if user_lat.contains("47.8097") && user_long.contains("7.17699") {
                cityName = "Cernay"
            }
            if user_lat.contains("43.70011") && user_long.contains("-79.4163") {
                cityName = "Toronto"
            }
            else {
                cityName = "Unknown"
            }
    
        print ("Displaying accelerometer data")
        
        //Convert longitudes and latitudes to string.

        let user_accelerometerXValue = String(format: "%f", myData.acceleration.x)
        let user_accelerometerYValue = String(format: "%f", myData.acceleration.y)
        let user_accelerometerZValue = String(format: "%f", myData.acceleration.z)
        
        
        print( user_accelerometerXValue)
        print( user_accelerometerYValue)
        print( user_accelerometerZValue)
        
        var speed = self.locationManager.location!.speed*3.6
        
        if speed <= 0
        {
            speed = 0
        }
        
        print("Displaying Speed")
        //--Displaying speed of the motion of the phone in kilometer per hour.
        print(speed)
        
       let roadTypes = ["Asphalt", "Concrete", "Earth", "Stones"]
       let detection = ["YES","NO"]
       let today = Date()
       let formatter1 = DateFormatter()
       formatter1.dateStyle = .short
       
       //print(formatter1.string(from: today))

       let nameRandLoc :String = "Location_\(Int.random(in: 0..<100))"
       
       
       let object: [String : Any] = [
           "Name": nameRandLoc,
           "City": cityName,
           "Latitude" : user_lat ,
           "Longitude" : user_long,
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
       
       

        self.database.child("AreasNames").observeSingleEvent(of: .value, with: { [self]snapshot in guard (snapshot.value as? [String: Any]) != nil
       else{
           database.child("AreasNames").childByAutoId().setValue(nameRandLoc)
           return
       }
       database.child("AreasNames").childByAutoId().setValue(nameRandLoc)
      
       })
       
        self.database.child("Areas").observeSingleEvent(of: .value, with: { [self]snapshot in guard (snapshot.value as? [String: Any]) != nil
       else{
           database.child("Areas").child(nameRandLoc).setValue(object)
           return
       }
       database.child("Areas").child(nameRandLoc).setValue(object)
      
       })
   
    
    }}
}
}
