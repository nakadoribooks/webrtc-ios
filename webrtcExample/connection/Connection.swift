//
//  Connection.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/08.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class Connection: NSObject, ConnectionInterface {

    private let wamp:WampInterface
    private let onAddedStream:ConnectionOnAddedStream
    private var webRtc:WebRTCInterface!
    private let myId:String
    private let _targetId:String
    
    required init(myId:String, targetId:String, wamp:WampInterface, onAddedStream:@escaping ConnectionOnAddedStream){
        self.myId = myId
        self._targetId = targetId
        self.wamp = wamp
        self.onAddedStream = onAddedStream
        
        super.init()
        
        webRtc = WebRTC(callbacks: (
            onCreateOffer: {(sdp:String) -> Void in
                self.wamp.publishOffer(targetId: targetId, sdp: sdp)
            }
            , onCreateAnswer: {(sdp:String) -> Void in
                self.wamp.publishAnswer(targetId: targetId, sdp: sdp)
            }
            , onIceCandidate: {(sdp:String, sdpMid:String, sdpMLineIndex:Int32) -> Void in
                
                let dic:NSDictionary = [
                    "type": "candidate"
                    , "sdpMid": sdpMid
                    , "sdpMLineIndex": sdpMLineIndex
                    , "candidate": sdp
                ]
                
                do{
                    let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
                    let jsonStr = String(bytes: jsonData, encoding: .utf8)!
                    self.wamp.publishCandidate(targetId: targetId, candidate: jsonStr)
                }catch let e{
                    print(e)
                }
                
            }
            , onAddedStream: {(stream:RTCMediaStream) -> Void in
                self.onAddedStream(stream)
            }
            , onRemoveStream: {(stream:RTCMediaStream) -> Void in
                
            }
        ))
        
    }
    
    deinit {
        print("connection deinit")
    }
    
    // MARK: interface
    
    var targetId:String?{
        get{
            return _targetId
        }
    }
    
    func receiveOffer(sdp:String){
        webRtc.receiveOffer(sdp: sdp)
    }
    
    func publishOffer(){
        print("publishOffer")
        webRtc.createOffer()
    }
    
    func receiveAnswer(sdp:String){
        webRtc.receiveAnswer(sdp: sdp)
    }
    
    func receiveCandidate(sdp:String, sdpMid:String, sdpMLineIndex:Int32){
        webRtc.receiveCandidate(sdp: sdp, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
    }
    
    func close(){
        print("close connection")
        webRtc.close()
    }
    
}
