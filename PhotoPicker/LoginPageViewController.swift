//
//  LoginPageViewController.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-01-23.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginPageViewController: UIViewController {
    

    
    private let label:UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Log In or Register"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        return label
    }()
    
    private let emailField:UITextField = {
        let emailField = UITextField()
        emailField.placeholder = "Email Address"
        emailField.layer.borderWidth = 1
        emailField.autocapitalizationType = .none
        emailField.leftViewMode = .always
        emailField.leftView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 0))
        emailField.layer.borderColor = UIColor.black.cgColor
        emailField.textColor = .white
        emailField.backgroundColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        return emailField
    }()
    
    private let passwordField:UITextField = {
        let passwordField = UITextField()
        passwordField.placeholder = "Password"
        passwordField.layer.borderWidth = 1
        passwordField.isSecureTextEntry = true
        passwordField.leftViewMode = .always
        passwordField.leftView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 0))
        passwordField.layer.borderColor = UIColor.black.cgColor
        passwordField.textColor = .white
        passwordField.backgroundColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        return passwordField
    }()
    
    private let button:UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Continue", for: .normal)
        return button
    }()
    
    private let signOutButton:UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(displayP3Red: 0.10980, green:0.26275, blue:0.56471, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Log out", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.view.backgroundColor = UIColor.systemBlue
        view.addSubview(label)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
        
        if FirebaseAuth.Auth.auth().currentUser != nil {
            
            var rootControler: UIViewController?
            
            rootControler = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "HomePage")
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = rootControler
            
            label.isHidden = true
            button.isHidden = true
            emailField.isHidden = true
            passwordField.isHidden = true
            
            
            view.addSubview(signOutButton)
            signOutButton.frame = CGRect(x: 20, y: 150, width: view.frame.size.width-40, height: 52)
            signOutButton.addTarget(self, action: #selector(logOutTapped), for: .touchUpInside)
            
            
        }
       
        
        
        
    }
    
    @objc private func logOutTapped() {
        do{
            try FirebaseAuth.Auth.auth().signOut()
            label.isHidden = false
            button.isHidden = false
            emailField.isHidden = false
            passwordField.isHidden = false
            signOutButton.removeFromSuperview()
        }
        catch {
            print("An error occurred")
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        label.frame = CGRect(x: 0, y: 100, width: view.frame.size.width, height: 80)
        
        emailField.frame = CGRect(x: 20, y: label.frame.origin.y+label.frame.size.height+10, width: view.frame.size.width-40, height: 50)
        
        passwordField.frame = CGRect(x: 20, y: emailField.frame.origin.y+label.frame.size.height+10, width: view.frame.size.width-40, height: 50)
        
        button.frame = CGRect(x: 20, y: passwordField.frame.origin.y+label.frame.size.height+10, width: view.frame.size.width-40, height: 80)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FirebaseAuth.Auth.auth().currentUser == nil {
            emailField.becomeFirstResponder()
        }
       
        else {
            
        }
    }
    
    
    
    
    @objc private func didTapButton()
    {
        print("Continue button taped")
        guard let email  = emailField.text, !email.isEmpty,
        let password = passwordField.text, !password.isEmpty else{
            print ("Missing field data")
            return
    }
        //Get auth instance
        //attempt sign in
        //if failure, present alert to create account
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] result,error in
            guard let StrongSelf = self else
            {
                return
            }
            
            guard error == nil else {
                StrongSelf.showCreateAccount(email:email,password:password)
                return
            }
            
            print("You have signed in didTapButton")
            
            var rootControler: UIViewController?
            
            rootControler = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "HomePage")
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = rootControler
        
            
            StrongSelf.label.isHidden = true
            StrongSelf.emailField.isHidden = true
            StrongSelf.passwordField.isHidden = true
            StrongSelf.button.isHidden = true
            
            StrongSelf.emailField.resignFirstResponder()
            StrongSelf.passwordField.resignFirstResponder()

            
    })
    }
    
        func showCreateAccount(email: String, password: String) {
            let alert = UIAlertController(title:"Create Account",
                                          message: "Would you like to create an account",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue",
                                          style: .default,
                                          handler: {_ in
                                            
                                        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {[weak self]result, error in
                                                guard let StrongSelf = self else
                                                {
                                                    return
                                                }
                                                
                                                guard error == nil else {
                                                    print("Account creation failed")
                                                    return
                                                }
                                                
                                                print("You have sucessfully created your account")
                                            
                                                
                    
                                                StrongSelf.emailField.text = ""
                                                StrongSelf.passwordField.text = ""
                                            
                                            let alert = UIAlertController(title: "You have sucessfully created your account", message: "You will be redirected to the login page", preferredStyle: .alert)
                                            alert.addAction(UIAlertAction(title: "Ok",
                                                                          style: .default,
                                                                          handler: {_ in
                                            }))
                                            self?.present(alert, animated:true)

                                                
                                            })
                                            
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel",
                                          style: .cancel,
                                          handler: {_ in
            }))
            present(alert, animated: true)
            
            
        }


}

