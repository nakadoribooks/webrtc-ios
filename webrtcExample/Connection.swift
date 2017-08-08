//
//  Connection.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/08.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias ConnectionOnAddedStream = (_ streamWrapper:StreamWrapper)->()

class StreamWrapper:NSObject{
    
    let stream:RTCMediaStream
    let targetId:String
    let view:UIView
    
    init(stream:RTCMediaStream, targetId:String, view:UIView){
        self.stream = stream
        self.targetId = targetId
        self.view = view
        super.init()
        
        let overlay = UIView()
        overlay.frame.size = view.frame.size
        view.addSubview(overlay)
        
        let labelBg = UIView()
        labelBg.frame = CGRect(x: 0, y: view.frame.size.height - 30, width: view.frame.size.width, height: 30)
        labelBg.backgroundColor = UIColor.white
        labelBg.alpha = 0.8
        overlay.addSubview(labelBg)
        
        let label = UILabel()
        label.frame = CGRect(x: 0, y: view.frame.size.height - 30, width: view.frame.size.width, height: 30)
        label.textAlignment = .center
        label.text = targetId
        label.textColor = UIColor.black
        overlay.addSubview(label)
    }
}

class Connection: NSObject {

    private let onAddedStream:ConnectionOnAddedStream
    private var webRtc:WebRTC!
    private let myId:String
    let targetId:String
    
    init(myId:String, targetId:String, onAddedStream:@escaping ConnectionOnAddedStream){
        self.myId = myId
        self.targetId = targetId
        self.onAddedStream = onAddedStream
        
        super.init()
        
        webRtc = WebRTC(callbacks: (
            onIceCandidate: {(iceCandidate:NSDictionary) -> Void in
                
                let jsonData = try! JSONSerialization.data(withJSONObject: iceCandidate, options: [])
                let jsonStr = String(bytes: jsonData, encoding: .utf8)!
                
                let wamp = Wamp.sharedInstance
                let topic = wamp.endpointCandidate(targetId: targetId)
                wamp.session.publish(topic, options: [:], args: [jsonStr], kwargs: [:])
            }
            , onAddedStream: {(stream:RTCMediaStream, view:UIView) -> Void in
                let streamWrapper = StreamWrapper(stream: stream, targetId: targetId, view:view)
                self.onAddedStream(streamWrapper)
            }
            , onRemoveStream: {(stream:RTCMediaStream) -> Void in
                
            }
        ))
        
        // for tricke ice
        subscribeCandidate()
    }
    
    private func subscribeCandidate(){
        let wamp = Wamp.sharedInstance
        let candidateTopic = wamp.endpointCandidate(targetId: myId)
        
        Wamp.sharedInstance.session.subscribe(candidateTopic, onSuccess: { (subscription) in
        }, onError: { (results, error) in
        }) { (results, args, kwArgs) in
            
            guard let candidateStr = args?.first as? String else{
                print(args?.first)
                print("no candidate")
                return
            }
            
            let data = candidateStr.data(using: String.Encoding.utf8)!
            let candidate = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                        
            self.webRtc.receiveCandidate(candidate: candidate)
        }
    }
    
    deinit {
        print("connection deinit")
    }
    
    func publishAnswer(offerSdp:NSDictionary){
        webRtc.receiveOffer(remoteSdp: offerSdp) { (answerSdp) in
            let wamp = Wamp.sharedInstance
            let topic = wamp.endpointAnswer(targetId: self.targetId)
            
            let jsonData = try! JSONSerialization.data(withJSONObject: answerSdp, options: [])
            let jsonStr = String(bytes: jsonData, encoding: .utf8)!
            
            Wamp.sharedInstance.session.publish(topic, options: [:], args: [self.myId, jsonStr], kwargs: [:])
        }
    }
    
    func publishOffer(){
        webRtc.createOffer { (offerSdp) in
            let wamp = Wamp.sharedInstance
            let topic = wamp.endpointOffer(targetId: self.targetId)
            
            let jsonData = try! JSONSerialization.data(withJSONObject: offerSdp, options: [])
            let jsonStr = String(bytes: jsonData, encoding: .utf8)!
            
            wamp.session.publish(topic, options: [:], args: [self.myId, jsonStr], kwargs: [:])
        }
    }
    
    func receiveAnswer(sdp:NSDictionary){
        webRtc.receiveAnswer(remoteSdp: sdp)
    }
    
    func receiveCnadidate(candidate:NSDictionary){
        
    }
    
    func close(){
        print("close connection")
        webRtc.close()
    }
    
}
