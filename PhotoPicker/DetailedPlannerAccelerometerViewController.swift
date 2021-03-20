//
//  DetailedPlannerAccelerometerViewController.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-03-20.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class DetailedPlannerAccelerometerViewController: UIViewController {

    @IBOutlet weak var lbl: UITextView!
    
    var name = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        lbl.text = name

        // Do any additional setup after loading the view.
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
