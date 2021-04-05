/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the AppDelegate subclass of UIApplicationDelegate.
*/


//Import Firebase to connect to firebase services
 import UIKit
 import Firebase


 @UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {

 var window: UIWindow?


 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    var rootControler: UIViewController?
    
    //Authenticate to firebase with bundle firebase
    if(FirebaseAuth.Auth.auth().currentUser != nil){
        rootControler = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "HomePage")
    }
    else {
        rootControler = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "LoginPage") as! LoginPageViewController
    }
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.window?.rootViewController = rootControler


     self.window?.makeKeyAndVisible()
   

     return true
     }
    
    //Configure Firebase
    override init() {
        FirebaseApp.configure()
    }
    
 }
