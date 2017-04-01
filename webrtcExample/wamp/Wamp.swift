//
//  Wamp.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit
import Swamp

protocol WampDelegate:class{
    
    func onReceiveAnswer(sdp:NSDictionary)
    func onReceiveOffer(sdp:NSDictionary)
    
}

class Wamp: NSObject, SwampSessionDelegate {

    static let sharedInstance = Wamp()
    
    private var swampSession:SwampSession?
    var delegate:WampDelegate?
    
    private override init() {
        super.init()        
    }
    
    func connect(){
//    nakadoribooks-webrtc.herokuapp.com
        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "wss://nakadoribooks-webrtc.herokuapp.com")!)
//        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "ws://192.168.1.2:8000")!)
//        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "ws://192.168.10.102:8000")!)
        let swampSession = SwampSession(realm: "realm1", transport: swampTransport)
        
        // Set delegate for callbacks
        swampSession.delegate = self
        
        self.swampSession = swampSession
        swampSession.connect()
    }
    
    func publishOffer(sdp:NSDictionary){
        swampSession?.publish("com.nakadoribook.webrtc.offer", options: [:], args: [sdp], kwargs: [:])
    }
    
    func publishAnswer(sdp:NSDictionary){
        swampSession?.publish("com.nakadoribook.webrtc.answer", options: [:], args: [sdp], kwargs: [:])
    }
    
    // MARK: private
    
    private func subscribe(){
        swampSession!.subscribe("com.nakadoribook.webrtc.offer", onSuccess: { subscription in
            // subscription can be stored for subscription.cancel()
        }, onError: { details, error in
            print("onError")
            print(details)
            print(error)
        }, onEvent: { details, results, kwResults in
            // Event data is usually in results, but manually check blabla yadayada
            print("onOffer")
            
            guard let arg = results?.first as? NSDictionary else{
                print("no args")
                print(results)
                return;
            }
            
            self.delegate?.onReceiveOffer(sdp: arg)
        })
        
        swampSession!.subscribe("com.nakadoribook.webrtc.answer", onSuccess: { subscription in
            // subscription can be stored for subscription.cancel()
        }, onError: { details, error in
            print("onError")
            print(details)
            print(error)
        }, onEvent: { details, results, kwResults in
            // Event data is usually in results, but manually check blabla yadayada
            print("onAnswer")
            
            guard let arg = results?.first as? NSDictionary else{
                print("no args")
                print(results)
                return;
            }
            
            self.delegate?.onReceiveAnswer(sdp: arg)
        })
        
    }
    
    // MARK: SwampSessionDelegate
    
    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String{
        return SwampCraAuthHelper.sign("secret123", challenge: extra["challenge"] as! String)
    }
    
    func swampSessionConnected(_ session: SwampSession, sessionId: Int){
        print("swampSessionConnected")
        print(sessionId)
        
        subscribe()
    }
    
    func swampSessionEnded(_ reason: String){
        print("swampSessionEnded")
        print(reason);
    }
    
}
