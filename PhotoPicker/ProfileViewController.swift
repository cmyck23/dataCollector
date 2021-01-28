//
//  ProfileViewController.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-01-27.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var LogOutButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func LogOut(_ sender: Any) {
        do{
            try FirebaseAuth.Auth.auth().signOut()
            print("Cliked on Sign Out!")
            var rootControler: UIViewController?
            
            if(FirebaseAuth.Auth.auth().currentUser != nil){
                rootControler = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "HomePage")
            }
            else {
                rootControler = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "LoginPage") as! LoginPageViewController
            }
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = rootControler        }
        catch {
            print("An error occurred")
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
