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
        
        createOffer()
        connect(iceServerUrlList: ["stun:23.21.150.121", "stun:stun.l.google.com:19302"])
    }
    
    private func createOffer(){
        webRTC.createOffer()
    }
    
    private func connect(iceServerUrlList:[String]){
        webRTC.connect(iceServerUrlList: iceServerUrlList)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

