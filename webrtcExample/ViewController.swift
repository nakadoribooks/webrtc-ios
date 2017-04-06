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
    private let wamp = Wamp.sharedInstance
    
    private let videoLayer = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 375))
    private let controlButton = UIButton()
    private let infomationLabel = UILabel()
    private var typeOffer:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webRTC.setup()
        
        view.addSubview(videoLayer)
        videoLayer.addSubview(webRTC.remoteView())
        videoLayer.addSubview(webRTC.localView())
        
        view.addSubview(controlButton)
        view.addSubview(infomationLabel)
        
        stateInitial()
    }
    
    private func connect(){
        
        webRTC.connect(iceServerUrlList: ["stun:stun.l.google.com:19302"], onCreatedLocalSdp: { (localSdp) in
            
            if self.typeOffer{
                self.wamp.publishOffer(sdp: localSdp)
            }else{
                self.wamp.publishAnswer(sdp: localSdp)
            }
            
        }, didGenerateCandidate: { (candidate) in
            
            self.wamp.publishCandidate(candidate: candidate)
            
        }, didReceiveRemoteStream: { () in
            self.stateWebrtcConnected()
        })
        
        wamp.connect(onConnected: { 
            self.stateConnected()
        }, onReceiveAnswer: { (answerSdp) in
            
            self.webRTC.receiveAnswer(remoteSdp: answerSdp)
            
        }, onReceiveOffer: { (offerSdp) in
            
            if self.typeOffer{
                return;
            }
            
            self.stateReceivedOffer()
            self.webRTC.receiveOffer(remoteSdp: offerSdp)
            
        }, onReceiveCandidate: { (candidate) in
            
            self.webRTC.receiveCandidate(candidate: candidate)
            
        })
        
    }
    
    private func changeButton(title:String, color:UIColor, enabled:Bool){
        controlButton.layer.borderColor = color.cgColor
        controlButton.setTitleColor(color, for: .normal)
        controlButton.setTitle(title, for: .normal)
        controlButton.isEnabled = enabled
        
        controlButton.removeTarget(self, action: nil, for: .allEvents)
    }
    
    private func changeInfomation(text:String, color:UIColor=UIColor.gray){
        infomationLabel.text = text
        infomationLabel.textColor = color
    }
    
    private func buttonAnimation(){
        controlButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        UIView.animate(withDuration: 0.2) { 
            self.controlButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
    
    // MARK: UIEvents
    
    private dynamic func tapOffer(){
        typeOffer = true
        
        buttonAnimation()
        
        stateOffering()
        
        webRTC.createOffer()
    }
    
    private dynamic func tapConnect(){
        buttonAnimation()
        
        stateConnecting()
        
        connect()
    }
    
    // MARK: states
    
    private func stateInitial(){
        controlButton.frame = CGRect(x: 20, y: windowHeight()-64-20, width: windowWidth()-40, height: 64)
        
        controlButton.layer.cornerRadius = 5;
        controlButton.layer.borderWidth = 2
        controlButton.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        changeButton(title: "Connect", color: UIColor.orange, enabled: true)
        controlButton.addTarget(self, action: #selector(ViewController.tapConnect), for: .touchUpInside)
        
        infomationLabel.frame = CGRect(x: 20, y: controlButton.frame.origin.y - 30 - 20, width: windowWidth()-40, height: 30)
        infomationLabel.font = UIFont.systemFont(ofSize: 20)
        infomationLabel.textAlignment = .center
    }
    
    private func stateConnected(){
        changeInfomation(text: "Connected!", color: UIColor.green)
        
        changeButton(title: "Send Offer", color: UIColor.blue, enabled: true)
        controlButton.addTarget(self, action: #selector(ViewController.tapOffer), for: .touchUpInside)
    }
    
    private func stateConnecting(){
        changeButton(title: "Connecting...", color: UIColor.orange, enabled: false)
        changeInfomation(text: "Connecting...")
    }
    
    private func stateOffering(){
        changeButton(title: "Offered", color: UIColor.gray, enabled: false)
        changeInfomation(text: "Offering", color: UIColor.blue)
    }

    private func stateReceivedOffer(){
        changeButton(title: "ReceivedOffer", color: UIColor.gray, enabled: false)
        changeInfomation(text: "CreatingAnswer...", color: UIColor.blue)
    }
    
    private func stateWebrtcConnected(){
        changeButton(title: "OK!", color: UIColor.gray, enabled: false)
        changeInfomation(text: "OK!", color: UIColor.green)
    }
    
}

