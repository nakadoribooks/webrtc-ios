//
//  ViewController.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WampDelegate, WebRTCDelegate {

    private let webRTC = WebRTC.sharedInstance
    private let wamp = Wamp.sharedInstance
    
    private let videoLayer = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 375))
    private let offerButton = UIButton(frame: CGRect(x: 20, y: 400, width: 100, height: 44))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webRTC.setup()
        webRTC.delegate = self
        
        view.addSubview(videoLayer)
        videoLayer.addSubview(webRTC.remoteView())
        videoLayer.addSubview(webRTC.localView())
        
        offerButton.layer.cornerRadius = 5;
        offerButton.layer.borderColor = UIColor.blue.cgColor
        offerButton.layer.borderWidth = 3
        offerButton.setTitleColor(UIColor.blue, for: .normal)
        offerButton.setTitle("Offer", for: .normal)
        offerButton.addTarget(self, action: #selector(ViewController.tapOffer), for: .touchUpInside)
        
        view.addSubview(offerButton)
        
        connect(iceServerUrlList: ["stun:stun.l.google.com:19302"])
        
        wamp.delegate = self
        wamp.connect()
    }
    
    // MARK: private
    
    private dynamic func tapOffer(){
        print("tapOffer")
        
        webRTC.createOffer { (sdp) in
            self.wamp.publishOffer(sdp: sdp)
        }
    }
    
    private func connect(iceServerUrlList:[String]){
        webRTC.connect(iceServerUrlList: iceServerUrlList)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: WampDelegate
    
    func onReceiveAnswer(sdp: NSDictionary) {
        webRTC.receiveAnswer(remoteSdp: sdp)
    }
    
    func onReceiveOffer(sdp: NSDictionary) {
        webRTC.receiveOffer(remoteSdp: sdp)
    }
    
    // MARK: WebRTCDelegate
    
    func onCreatedAnswer(sdp: NSDictionary) {
        wamp.publishAnswer(sdp: sdp)
    }
    
    func didAddedRemoteStream() {
        
    }
    

}

