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

    
    @IBOutlet weak var textViewInfo: UITextView!
    @IBOutlet weak var forgotButton:UIButton!
    
    
    @IBOutlet weak var LogOutButton: UIBarButtonItem!
    override func viewDidLoad() {
        
        showInformation()
        
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    
    
    func showInformation()
    {
        let user = Auth.auth().currentUser
        if let user = user {
          // The user's ID, unique to the Firebase project.
          // Do NOT use this value to authenticate with your backend server,
          // if you have one. Use getTokenWithCompletion:completion: instead.
          let email = user.email
          
            //print(email as Any)
          // ...
            
            self.textViewInfo.text = "My username: "+email!
        }
    }
    
    
    
    
    @IBAction func LogOut(_ sender: Any) {
        do{
            try FirebaseAuth.Auth.auth().signOut()
            //print("Cliked on Sign Out!")
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
    
    @IBAction func resetPasswordDidTapped(_ sender: Any){
        
        let user = Auth.auth().currentUser
        if let user = user {
          // The user's ID, unique to the Firebase project.
          // Do NOT use this value to authenticate with your backend server,
          // if you have one. Use getTokenWithCompletion:completion: instead.
          let email = user.email
            
            let myEmail = String(email ?? "")
          
            Auth.auth().sendPasswordReset(withEmail: myEmail) { error in
              // ...
                
                //print("Clicked on forgot password!")
                
                
                let alert = UIAlertController(title:"Email Sent!",
                                              message: "An email will be sent to " + email!,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok",
                                              style: .default,
                                              handler: {_ in
                                                
                                                
                }))
                
                self.present(alert, animated: true)
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
