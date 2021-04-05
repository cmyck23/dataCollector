//
//  DataCollectorPage.swift
//  Road Analyzer
//
//  Created by Myckael on 2021-01-22.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class DataCollectorPage: UIViewController {
    
    @IBOutlet weak var button: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        overrideUserInterfaceStyle = .light
        button.layer.cornerRadius = 10.0

    }
    
}
