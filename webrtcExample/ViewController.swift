//
//  ViewController.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let webRTC = WebRTC.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webRTC.setup()
        view.addSubview(webRTC.localView())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

