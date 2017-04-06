//
//  Wamp.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit
import Swamp

class Wamp: NSObject, SwampSessionDelegate {

    static let sharedInstance = Wamp()
    
    private static let AnswerTopic = "com.nakadoribook.webrtc.answer"
    private static let OfferTopic = "com.nakadoribook.webrtc.offer"
    
    private var swampSession:SwampSession?
    private var onConnected:(()->())?
    private var onReceiveAnswer:((_ sdp:NSDictionary)->())?
    private var onReceiveOffer:((_ sdp:NSDictionary)->())?
    
    private override init() {
        super.init()        
    }
    
    func connect(onConnected:@escaping (()->()), onReceiveAnswer:@escaping ((_ sdp:NSDictionary)->()), onReceiveOffer:@escaping ((_ sdp:NSDictionary)->())){
        self.onConnected = onConnected
        self.onReceiveAnswer = onReceiveAnswer
        self.onReceiveOffer = onReceiveOffer

//        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "wss://nakadoribooks-webrtc.herokuapp.com")!)
        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "ws://192.168.1.2:8000")!)
        let swampSession = SwampSession(realm: "realm1", transport: swampTransport)
        swampSession.delegate = self
        swampSession.connect()
        
        self.swampSession = swampSession
    }
    
    func publishOffer(sdp:NSDictionary){
        swampSession?.publish(Wamp.OfferTopic, options: [:], args: [sdp], kwargs: [:])
    }
    
    func publishAnswer(sdp:NSDictionary){
        swampSession?.publish(Wamp.AnswerTopic, options: [:], args: [sdp], kwargs: [:])
    }
    
    // MARK: private
    
    private func subscribe(){
        _subscribeOffer()
        _subscribeAnswer()
    }
    
    private func _subscribeOffer(){
        swampSession!.subscribe(Wamp.OfferTopic, onSuccess: { subscription in
        }, onError: { details, error in
            print("onError: \(error)")
        }, onEvent: { details, results, kwResults in
            
            guard let sdp = results?.first as? NSDictionary else{
                print("no args")
                return;
            }
            
            if let callback = self.onReceiveOffer{
                callback(sdp)
            }
        })
    }
    
    private func _subscribeAnswer(){
        swampSession!.subscribe(Wamp.AnswerTopic, onSuccess: { subscription in
            
        }, onError: { details, error in
            print("onError: \(error)")
        }, onEvent: { details, results, kwResults in
            
            guard let sdp = results?.first as? NSDictionary else{
                print("no args")
                return;
            }
            
            if let callback = self.onReceiveAnswer{
                callback(sdp)
            }
        })
    }
    
    // MARK: SwampSessionDelegate
    
    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String{
        return SwampCraAuthHelper.sign("secret123", challenge: extra["challenge"] as! String)
    }
    
    func swampSessionConnected(_ session: SwampSession, sessionId: Int){
        print("swampSessionConnected: \(sessionId)")
        
        if let callback = self.onConnected{
            callback()
        }
        
        subscribe()
    }
    
    func swampSessionEnded(_ reason: String){
        print("swampSessionEnded: \(reason)")
    }
    
}
