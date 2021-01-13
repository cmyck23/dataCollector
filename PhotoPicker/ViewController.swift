/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The main view controller for this sample app.
 */

import UIKit
import AVFoundation
import UIKit
import CoreMotion
import CoreLocation
import AVFoundation
import CoreMedia
import CoreVideo
import FirebaseDatabase
import FirebaseStorage

class APLViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate  {
    
    var motionManager = CMMotionManager()
    
    // Used to start getting the users location
    let locationManager = CLLocationManager()
    
    
    //Create the datatype that will contain the information for each image capture.
    public var imagesMetadata:[Dictionary<String, AnyObject>] =  Array()
    
    //We will create a dictionnary to store the rows values according to the columns names.
    //This will be used later to create the csv file.
    
    public var diction = Dictionary<String, AnyObject>()
    
    
    
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var cameraButton: UIBarButtonItem?
    @IBOutlet var overlayView: UIView?
    
    var index = 0
    
    
    
    /// The camera controls in the overlay view.
    //@IBOutlet var takePictureButton: UIBarButtonItem?
    @IBOutlet var startStopButton: UIBarButtonItem?
    //@IBOutlet var delayedPhotoButton: UIBarButtonItem?
    @IBOutlet var doneButton: UIBarButtonItem?
    
    /// An image picker controller instance.
    var imagePickerController = UIImagePickerController()
    
    var cameraTimer = Timer()
    /// An array for storing captured images to display.
    //var capturedImages = [UIImage]()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For use when the app is open & in the background
        locationManager.requestAlwaysAuthorization()
        
        // For use when the app is open
        //locationManager.requestWhenInUseAuthorization()
        
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.startUpdatingLocation()
        }
        
        imagePickerController.modalPresentationStyle = .currentContext
        /*
         Assign a delegate for the image picker. The delegate receives
         notifications when the user picks an image or movie, or exits the
         picker interface. The delegate also decides when to dismiss the picker
         interface.
         */
        imagePickerController.delegate = self
        
        /*-------
         This app requires use of the device's camera. The app checks for device
         availability using the `isSourceTypeAvailable` method. If the
         camera isn't available, the app removes the camera button from the
         custom user interface.
         */
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            toolbarItems = self.toolbarItems?.filter { $0 != cameraButton }
        }
    }
    
    
    // If we have been deined access give the user the option to change it
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.denied) {
            showLocationDisabledPopUp()
        }
    }
    
    // Show the popup to the user if we have been denied access
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Background Location Access Disabled",
                                                message: "In order to deliver pizza we need your location",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        
        self.present(alertController, animated: true, completion: nil)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        
        //This is the interval to update the acceleromter
        //motionManager.accelerometerUpdateInterval = 2
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            
        }
    }
    
    // MARK: - Toolbar Actions
    
    /// - Tag: CameraSourceType
    @IBAction func showImagePickerForCamera(_ sender: UIBarButtonItem) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if authStatus == AVAuthorizationStatus.denied {
            // The system denied access to the camera. Alert the user.
            
            /*
             The user previously denied access to the camera. Tell the user this
             app requires camera access.
             */
            let alert = UIAlertController(title: "Unable to access the Camera",
                                          message: "To turn on camera access, choose Settings > Privacy > Camera and turn on Camera access for this app.",
                                          preferredStyle: UIAlertController.Style.alert)
            
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(okAction)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
                // Take the user to the Settings app to change permissions.
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        // The resource finished opening.
                    })
                }
            })
            alert.addAction(settingsAction)
            
            present(alert, animated: true, completion: nil)
        } else if authStatus == AVAuthorizationStatus.notDetermined {
            /*
             The user never granted or denied permission for media capture with
             the camera. Ask for permission.
             
             Note: The app must provide a `Privacy - Camera Usage Description`
             key in the Info.plist with a message telling the user why the app
             is requesting access to the device’s camera. See this app's
             Info.plist for such an example usage description.
             */
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.showImagePicker(sourceType: UIImagePickerController.SourceType.camera, button: sender)
                    }
                }
            })
        } else {
            /*
             The user granted permission to access the camera. Present the
             picker for capture.
             
             Set the image picker `sourceType` property to
             `UIImagePickerController.SourceType.camera` to configure the picker
             for media capture instead of browsing saved media.
             */
            showImagePicker(sourceType: UIImagePickerController.SourceType.camera, button: sender)
        }
    }
    
    /**
     Set `sourceType` to `UIImagePickerController.SourceType.photoLibrary` to
     present a browser that provides access to all the photo albums on the
     device, including the Camera Roll album.
     */
    @IBAction func showImagePickerForPhotoPicker(_ sender: UIBarButtonItem) {
        showImagePicker(sourceType: UIImagePickerController.SourceType.photoLibrary, button: sender)
    }
    
    func showImagePicker(sourceType: UIImagePickerController.SourceType, button: UIBarButtonItem) {
        // Stop animating the images in the view.
        if (imageView?.isAnimating)! {
            imageView?.stopAnimating()
        }
        //		if !capturedImages.isEmpty {
        //			capturedImages.removeAll()
        //		}
        
        imagePickerController.sourceType = sourceType
        imagePickerController.modalPresentationStyle =
            (sourceType == UIImagePickerController.SourceType.camera) ?
            UIModalPresentationStyle.fullScreen : UIModalPresentationStyle.popover
        
        let presentationController = imagePickerController.popoverPresentationController
        // Display a popover from the UIBarButtonItem as an anchor.
        presentationController?.barButtonItem = button
        presentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        if sourceType == UIImagePickerController.SourceType.camera {
            /*
             The user tapped the camera button in the app's interface which
             specifies the device’s built-in camera as the source for the image
             picker controller.
             */
            
            /*
             Hide the default controls.
             This sample provides its own custom controls for still image
             capture in an overlay view.
             */
            imagePickerController.showsCameraControls = false
            
            /*
             Apply the overlay view. This view contains a toolbar with custom
             controls for capturing still images in various ways.
             */
            overlayView?.frame = (imagePickerController.cameraOverlayView?.frame)!
            imagePickerController.cameraOverlayView = overlayView
        }
        
        /*
         The creation and configuration of the camera or media browser
         interface is now complete.
         
         Asynchronously present the picker interface using the
         `present(_:animated:completion:)` method.
         */
        present(imagePickerController, animated: true, completion: {
            // The block to execute after the presentation finishes.
        })
    }
    
    // MARK: - Camera View Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        if cameraTimer.isValid {
            cameraTimer.invalidate()
        }
        //finishAndUpdate()
    }
    /// - Tag: TakePicture
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        imagePickerController.takePicture()
    }
    
    
    /// - Tag: PhotoAtInterval
    @IBAction func startTakingPicturesAtIntervals(_ sender: UIBarButtonItem) {
        
        // Start the timer to take a photo every 5 seconds.
        
        startStopButton?.title = NSLocalizedString("Stop", comment: "Title for overlay view controller start/stop button")
        startStopButton?.action = #selector(stopTakingPicturesAtIntervals)
        
        // Enable these buttons while capturing photos.
        doneButton?.isEnabled = false
        //		delayedPhotoButton?.isEnabled = false
        //takePictureButton?.isEnabled = false
        
        
        
        
        // Start taking pictures.
        cameraTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.viewDidAppear(true)
            
            //self.motionManager.accelerometerUpdateInterval = 0.2
            
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
                    
//                    //Convert longitudes and latitudes to string.
//
//                    let user_lat = String(format: "%f", self.locationManager.location!.coordinate.latitude)
//                    let user_long = String(format: "%f", self.locationManager.location!.coordinate.longitude)
                    
                   
                    print(self.locationManager.location!.coordinate.latitude)
                    print(self.locationManager.location!.coordinate.longitude)
                    print("Displaying Speed")
                    //--Displaying speed of the motion of the phone in kilometer per hour.
                    print(self.locationManager.location!.speed*3.6)
                    
                    print ("Displaying accelerometer data")
                    
//                    //Convert longitudes and latitudes to string.
//
//                    let user_accelerometerXValue = String(format: "%f", myData.acceleration.x)
//                    let user_accelerometerYValue = String(format: "%f", myData.acceleration.y)
//                    let user_accelerometerZValue = String(format: "%f", myData.acceleration.z)
                    
                    
                    print( myData.acceleration.x)
                    print( myData.acceleration.y)
                    print( myData.acceleration.z)
                    
                    
            
                    
                    
                }
                
                
            }
            
            self.imagePickerController.takePicture()
            
            
            print("Calling  CSV Function")
           
            
        }
    }
    
    /// - Tag: StopTakingPictures
    @IBAction func stopTakingPicturesAtIntervals(_ sender: UIBarButtonItem) {
        // Stop and reset the timer.
        cameraTimer.invalidate()
        
        //finishAndUpdate()
        
        // Make these buttons available again.
        self.doneButton?.isEnabled = true
        //self.takePictureButton?.isEnabled = true
        //		self.delayedPhotoButton?.isEnabled = true
        
        startStopButton?.title = NSLocalizedString("Start", comment: "Title for overlay view controller start/stop button")
        startStopButton?.action = #selector(startTakingPicturesAtIntervals)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    /**
     You must implement the following methods that conform to the
     `UIImagePickerControllerDelegate` protocol to respond to user interactions
     with the image picker.
     
     When the user taps a button in the camera interface to accept a newly
     captured picture, the system notifies the delegate of the user’s choice by
     invoking the `imagePickerController(_:didFinishPickingMediaWithInfo:)`
     method. Your delegate object’s implementation of this method can perform
     any custom processing on the passed media, and should dismiss the picker.
     The delegate methods are always responsible for dismissing the picker when
     the operation completes.
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        //Create an image when the phone starts taking pictures.
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        
        print("Trying to print image description")
        
        
        //Create a storage object reference for firebase
        let storage = Storage.storage().reference()
        
        
        //Get current latitude and save it as a string.
        let user_lat = String(format: "%f", self.locationManager.location!.coordinate.latitude)
        //Get current longitude and save it as a string.
        let user_long = String(format: "%f", self.locationManager.location!.coordinate.longitude)
        
        //Create a metadata that contains the gps coordinates
        //This will be sent with the image on firebase
        let metadataImage = StorageMetadata()
        metadataImage.customMetadata = ["Longitude" : user_long,
        "Latitude" : user_lat]
        
    
        let currentTime = Date().toMillis()
        //print(currentTime!)
        
        
        //Send the current image (upload) to firebase
        storage.child("images/image\(currentTime!).jpg").putData(image.jpegData(compressionQuality: 0.2)!, metadata: metadataImage, completion: { _, error in
            guard error == nil else {
                print("Failed to uplaod")
                return
            }
        })
        
    }
    
    /**
     If the user cancels the operation, the system invokes the delegate's
     `imagePickerControllerDidCancel(_:)` method, and you should dismiss the
     picker.
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: {
            /*
             The dismiss method calls this block after dismissing the image picker
             from the view controller stack. Perform any additional cleanup here.
             */
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: - Utilities
private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
}

private func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
