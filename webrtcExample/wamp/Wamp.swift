//
//  Wamp.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit
import Swamp


enum WampTopic:String{
    
    case callme = "com.nakadoribook.webrtc.[roomId].callme"
    , close = "com.nakadoribook.webrtc.[roomId].close"
    , answer = "com.nakadoribook.webrtc.[roomId].[id].answer"
    , offer = "com.nakadoribook.webrtc.[roomId].[id].offer"
    , candidate = "com.nakadoribook.webrtc.[roomId].[id].candidate"

}

typealias WampOnOpenHandler = (()->())
typealias WampReceiveAnswerHandler = ((_ targetId:String, _ sdp:NSDictionary)->())
typealias WampReceiveOfferHandler = ((_ targetId:String, _ sdp:NSDictionary)->())
typealias WampReceiveCandidateHandler = ((_ targetId:String, _ candidate:NSDictionary)->())
typealias WampReceiveCallmeHandler = ((_ targetId:String)->())
typealias WampOncloseConnectionHandler = ((_ targetId:String)->())

typealias WampCallbacks = (onOpen:WampOnOpenHandler
    , onReceiveAnswer:WampReceiveAnswerHandler
    , onReceiveOffer:WampReceiveOfferHandler
    , onReceiveCallme:WampReceiveCallmeHandler
    , onCloseConnection:WampOncloseConnectionHandler)

class Wamp: NSObject, SwampSessionDelegate {

    static let sharedInstance = Wamp()
    private var _session:SwampSession!
    
    private override init() {
        super.init()        
    }
    
    deinit {
        print("deinit Wamp")
    }
    
    var session:SwampSession{
        get{
            return _session
        }
    }
    
    func connect(){
        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "wss://nakadoribooks-webrtc.herokuapp.com")!)
        let swampSession = SwampSession(realm: "realm1", transport: swampTransport)
        swampSession.delegate = self
        swampSession.connect()
    }
    
    // MARK: private
    
    private func resultToSdp(results:[Any]?)->NSDictionary?{
        
        if let sdp = results?.first as? NSDictionary{
            return sdp;
        }
        
        return nil;
    }
    
    // MARK: SwampSessionDelegate
    
    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String{
        return SwampCraAuthHelper.sign("secret123", challenge: extra["challenge"] as! String)
    }
    
    func swampSessionConnected(_ session: SwampSession, sessionId: Int){
        self._session = session
        
        // subscribe
        print("answerTopic", endpointAnswer(targetId: userId))
        
        session.subscribe(endpointAnswer(targetId: userId), onSuccess: { (subscription) in
        }, onError: { (details, error) in
        }) { (details, args, kwArgs) in
            print("onReceiveAnswer")
            guard let args = args, let targetId = args[0] as? String, let sdpString = args[1] as? String else{
                print("no args answer")
                return
            }
            
            let sdp = try! JSONSerialization.jsonObject(with: sdpString.data(using: .utf8)!, options: .allowFragments) as! NSDictionary
            self.callbacks.onReceiveAnswer(targetId, sdp)
        }
        
        print("offerTopic", endpointOffer(targetId: userId))
        session.subscribe(endpointOffer(targetId: userId), onSuccess: { (subscription) in
        }, onError: { (details, error) in
        }) { (details, args, kwArgs) in
            guard let args = args, let targetId = args[0] as? String, let sdpString = args[1] as? String else{
                print("no args offer")
                return
            }
            
            let sdp = try! JSONSerialization.jsonObject(with: sdpString.data(using: .utf8)!, options: .allowFragments) as! NSDictionary
            self.callbacks.onReceiveOffer(targetId, sdp)
        }
        
        session.subscribe(endpointCallme(), onSuccess: { (subscription) in
        }, onError: { (details, error) in
        }) { (details, args, kwArgs) in
            guard let args = args, let targetId = args[0] as? String else{
                print("no args callMe")
                return
            }
            
            if targetId == self.userId{
                return;
            }
            self.callbacks.onReceiveCallme(targetId)
        }
        
        session.subscribe(endpointClose(), onSuccess: { (subscription) in
        }, onError: { (details, error) in
        }) { (details, args, kwArgs) in
            guard let args = args, let targetId = args[0] as? String else{
                print("no args close")
                return
            }
            
            if targetId == self.userId{
                return;
            }
            
            self.callbacks.onCloseConnection(targetId)
        }

        
        self.callbacks.onOpen()
    }
    
    func swampSessionEnded(_ reason: String){
        print("swampSessionEnded: \(reason)")
    }
    
    private var roomKey:String!
    private var userId:String!
    private var callbacks:WampCallbacks!
    
    func setup(roomKey:String, userId:String, callbacks:WampCallbacks){
        self.roomKey = roomKey
        self.userId = userId
        self.callbacks = callbacks
    }
    
    static let HandshakeEndpint = "wss://nakadoribooks-webrtc.herokuapp.com"
    
    private func roomTopic(base:String)->String{
        return base.replacingOccurrences(of: "[roomId]", with: self.roomKey)
    }
    
    func endpointAnswer(targetId:String)->String{
        return self.roomTopic(base: WampTopic.answer.rawValue.replacingOccurrences(of: "[id]", with: targetId))
    }
    
    func endpointOffer(targetId:String)->String{
        return self.roomTopic(base: WampTopic.offer.rawValue.replacingOccurrences(of: "[id]", with: targetId))
    }
    
    func endpointCandidate(targetId:String)->String{
        return self.roomTopic(base: WampTopic.candidate.rawValue.replacingOccurrences(of: "[id]", with: targetId))
    }
    
    func endpointCallme()->String{
        return self.roomTopic(base: WampTopic.callme.rawValue)
    }
    
    func endpointClose()->String{
        return self.roomTopic(base: WampTopic.close.rawValue)
    }
    
}
