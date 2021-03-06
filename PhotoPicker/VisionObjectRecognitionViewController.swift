/*
See LICENSE folder for this sample’s licensing information.
Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/


//Import the required libraries
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
    
    
    //Create a reference object to firebase.
    var database = Database.database().reference()
    var motionManager = CMMotionManager()
    
    let firestoreDatabase = Firestore.firestore()
    
    // Used to start getting the users location.
    let locationManager = CLLocationManager()
    
    // This is used to get the cities names from locations.
    let manager = CLLocation()
    var completion: ((CLLocation)-> Void)?
    
    var acceleromterAllowed = false

    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    
    @IBOutlet var text: UITextView!
    
    
    /// Function that is run when opening the page of the application for the first time.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        
    
        // Do any additional setup after loading the view.
        
        
    }
    
    ///Function that set what will appear
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
        
            ///Call the function viewLoadSetup, used for loading the machine learning model.
                
           viewLoadSetup()

        }
    
    
    func viewLoadSetup(){
          // setup view did load here
            ///Call the function that will display the IRI Analysis
        
        if acceleromterAllowed == true {
            showIRI()
        }
         }
    
    ///Function to load the machine learning.
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
                    // This is the results from the Machine Learning
                    if let results = request.results {
                        // Display results onto the screen of the device.
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
    
    ///This functions creates and displays results on the screen in the "Analysis" section.
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
        
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            
            // Every time a result is found by the AI, send the results for saving
            addNewEntry(typeOfDefect: String(topLabelObservation.identifier))
            
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    /// This function sets the camera settings
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
    
    ///Function to initialize all settings
    override func setupAVCapture() {
        super.setupAVCapture()
        
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        // start the capture
        startCaptureSession()
        acceleromterAllowed = true
        showIRI()
    }
    
    /// Function for detection results and rendering.
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
    
    ///Function that updates the graphics on the "Analysis" Page
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
    
    ///Create the text inside the rectangle and choose parameters such as font, colors and size
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        
        let tempIdentifierString = String(identifier.prefix(2))
    
        
        let formattedString = NSMutableAttributedString(string: String(format: "\(tempIdentifierString)\n %.2f", confidence))
        
        
        
        ///Display each type of defect with a different color. Bright colors were used to ease visualization.
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        
        if (tempIdentifierString == "Ma")
        {
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: tempIdentifierString.count+6))
            formattedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.cyan], range: NSRange(location: 0, length: tempIdentifierString.count+6))
            
        }
        else if (tempIdentifierString == "Mi")
        {
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: tempIdentifierString.count+6))
            formattedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.magenta], range: NSRange(location: 0, length: tempIdentifierString.count+6))
            
        }
        else
        {
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: tempIdentifierString.count+6))
            formattedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.orange], range: NSRange(location: 0, length: tempIdentifierString.count+6))
            
        }
        
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        //textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.5, 0.5, 0.5, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    
    ///Function to create the frame where the text will be place. Also, the size depends on the size of the defect detected.
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.11, 0.26, 0.56, 0.5])
        shapeLayer.cornerRadius = 7
        
        // Update firebase when a new object is detected
        //addNewEntry()
        
        return shapeLayer
    }
    
    /// This function had for objective to create dummy data, not of use anymore.
    public func displayButtonToGenerateValue()
   {
        database.child("Area_38").observeSingleEvent(of: .value, with: {snapshot in guard (snapshot.value as? [String: Any]) != nil
       else{return
           
       }
       
       })
       
       //Create a button to generate a random area with entries
       let button = UIButton(frame: CGRect(x: 20, y: 200,width: view.frame.size.width-40 ,height: 50 ))
       button.setTitle("Generate Random Entry", for: .normal)
       button.setTitleColor(.white, for: .normal)
       button.backgroundColor = .link

       view.addSubview(button)
       button.addTarget(self, action: #selector(addNewEntry), for: .touchUpInside)
   }
    
    ///Stop acceleromter and analyzis when
    override func viewWillDisappear(_ animated: Bool){
    
        self.motionManager.stopAccelerometerUpdates()
        
    }
    
    ///Function to display the current IRI on the analysis page
    func showIRI(){
        
        self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let myData = data
            {
                //--This is to create a date object to display the time later.
                
                
                let currentDateTime = Date()
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                formatter.dateStyle = .long
                
                _ = formatter.string(from: currentDateTime)
                
            
                
                //Get current latitude and save it as a string.
                _ = String(format: "%f", self.locationManager.location!.coordinate.latitude)
                //Get current longitude and save it as a string.
                _ = String(format: "%f", self.locationManager.location!.coordinate.longitude)
                
                
                
                //Convert longitudes and latitudes to string.
                _ = String(format: "%f", myData.acceleration.x)
                _ = String(format: "%f", myData.acceleration.y)
                _ = String(format: "%f", myData.acceleration.z)
                
               
                
                var speed = self.locationManager.location!.speed*3.6
                
                //This is the value that we obtained for the average Z-Value
                let averageZValue = -0.02960339
                
                var roughnessIndex = 0.0
                
                if speed <= 0
                {
                    speed = 0
                    roughnessIndex = 0
                    self.text.textColor = UIColor.green
                    self.text.text = ("IRI: No Defect Detected : "+String(roughnessIndex))
                    
                }
                else if speed >= 45 && speed < 70
                {
                    roughnessIndex = (sqrt(pow(myData.acceleration.x-averageZValue,2))/speed)*100
                    
                    if (roughnessIndex > 2.5)
                    {
                        self.text.textColor = UIColor.red
                        self.text.text = ("IRI: Potential Defect Detected : \n"+String(roughnessIndex))
                        self.addNewEntryAccelAnalysis()
                    }
                    else{
                        self.text.textColor = UIColor.green
                        self.text.text = ("IRI: No Defect Detected : \n"+String(roughnessIndex))
                    }
                    
                }
                else if speed >= 70 && speed < 100 {
                    roughnessIndex = (sqrt(pow(myData.acceleration.x-averageZValue,2))/speed)*100
                    
                    if (roughnessIndex > 2.0)
                    {
                        self.text.textColor = UIColor.red
                        self.text.text = ("IRI: Potential Defect Detected : \n"+String(roughnessIndex))
                        self.addNewEntryAccelAnalysis()
                    }
                    else{
                        self.text.textColor = UIColor.green
                        self.text.text = ("IRI: No Defect Detected : \n"+String(roughnessIndex))
                    }
                }
                else if speed >= 100
                {
                    roughnessIndex = (sqrt(pow(myData.acceleration.x-averageZValue,2))/speed)*100
                    
                    if (roughnessIndex > 1.5)
                    {
                        self.text.textColor = UIColor.red
                        self.text.text = ("IRI: Potential Defect Detected : \n"+String(roughnessIndex))
                        self.addNewEntryAccelAnalysis()
                    }
                    else{
                        self.text.textColor = UIColor.green
                        self.text.text = ("IRI: No Defect Detected : \n"+String(roughnessIndex))
                    }
                }
                else {
                    self.text.textColor = UIColor.green
                    self.text.text = ("IRI: No Defect Detected : "+String(roughnessIndex))
                }
    
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
    ///This function adds  new defect to an existing or current location on  firebase for the acceleromter analysis
    @objc public func addNewEntryAccelAnalysis()
   {
    
    var location_Name = "Unknown"
        
        //--This is to create a date object to display the time later.
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
    else if speed >= 45 {

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
                    locationName in self!.title = "Analyzing Road"
                    location_Name = locationName ?? "Unknown"
                    
                    //print(location_Name as Any)
                    
                    if location_Name != "Unknown" {
                        
                        print(location_Name as Any)
                    
                    self!.firestoreDatabase.collection("AreasAccelerometer").document(location_Name).getDocument{(document, error) in
                        
                        if error == nil{
                            
                            if document != nil && document!.exists{
                                
                            
                                if location_Name != "Unknown" {
                                    let incrementer: Double = 1

                                    self!.firestoreDatabase.collection("AreasAccelerometer").document(location_Name).updateData([
                                            "Total Defects" : FieldValue.increment(incrementer),"Last Update":formatter1.string(from: today)])
                                }
                                
                            }
                            
                            else
                            {
                                
                                if location_Name != "Unknown" {
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
}
    
    ///This function adds  new defect to an existing or current location on  firebase for the image AI Analysis
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
                    locationName in self!.title = "Analyzing Road"
                    location_Name = locationName ?? "Unknown"
                    
                    //print(location_Name as Any)
                
                    self!.firestoreDatabase.collection("Areas").document(location_Name).getDocument{(document, error) in
                        
                        if error == nil{
                            
                            // Add and update information for existing area
                            if document != nil && document!.exists{
                                
                                if location_Name != "Unknown" {
                                    print(location_Name as Any)
                                    
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
                                
                                self!.firestoreDatabase.collection("Areas").document(location_Name).setData([
                                "Last Updated":formatter1.string(from: today)
                                ],merge: true)
                                
                                if location_Name != "Unknown" {
                                    print(location_Name as Any)
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
                                        "Major Cracks Number":0,"Minor Cracks Number":1,"Potholes Number":0,"Total Defects":1,
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
   }

   }
