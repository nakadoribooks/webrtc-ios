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
    , answer = "com.nakadoribook.webrtc.[roomId].[userId].answer"
    , offer = "com.nakadoribook.webrtc.[roomId].[userId].offer"
    , candidate = "com.nakadoribook.webrtc.[roomId].[userId].candidate"

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
    , onCloseConnection:WampOncloseConnectionHandler
    , onReceiveCandidate:WampReceiveCandidateHandler)

class Wamp: NSObject, SwampSessionDelegate {

    private var session:SwampSession!
    
    private let roomId:String
    private let userId:String
    private let callbacks:WampCallbacks
    
    init(roomId:String, userId:String, callbacks:WampCallbacks){
        self.roomId = roomId
        self.userId = userId
        self.callbacks = callbacks
        super.init()
    }
    
    deinit {
        print("deinit Wamp")
    }
    
    // MARK: interface
    
    func connect(){
        let swampTransport = WebSocketSwampTransport(wsEndpoint:  URL(string: "wss://nakadoribooks-webrtc.herokuapp.com")!)
        let swampSession = SwampSession(realm: "realm1", transport: swampTransport)
        swampSession.delegate = self
        swampSession.connect()
    }
    
    func publishCallme(){
        let topic = self.callmeTopic()
        self.session.publish(topic, options: [:], args: [self.userId], kwargs: [:])
    }
    
    func publishOffer(targetId:String ,sdp:String){
        let topic = self.offerTopic(userId: targetId)
        self.session.publish(topic, options: [:], args: [self.userId, sdp], kwargs: [:])
    }
    
    func publishAnswer(targetId:String, sdp:String){
        let topic = self.answerTopic(userId: targetId)
        self.session.publish(topic, options: [:], args: [self.userId, sdp], kwargs: [:])
    }
    
    func publishCandidate(targetId:String, candidate:String){
        let topic = self.candidateTopic(userId: targetId)
        self.session.publish(topic, options: [:], args: [self.userId, candidate], kwargs: [:])
    }
    
    // MARK: 
    
    private func onConnect(){
        // subscribe
        
        session.subscribe(answerTopic(userId: userId), onSuccess: { (subscription) in
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
        
        session.subscribe(offerTopic(userId: userId), onSuccess: { (subscription) in
        }, onError: { (details, error) in
        }) { (details, args, kwArgs) in
            guard let args = args, let targetId = args[0] as? String, let sdpString = args[1] as? String else{
                print("no args offer")
                return
            }
            
            let sdp = try! JSONSerialization.jsonObject(with: sdpString.data(using: .utf8)!, options: .allowFragments) as! NSDictionary
            self.callbacks.onReceiveOffer(targetId, sdp)
        }
        
        session.subscribe(candidateTopic(userId: userId), onSuccess: { (subscription) in
        }, onError: { (results, error) in
        }) { (results, args, kwArgs) in
            
            guard let targetId = args?[0] as? String, let candidateStr = args?[1] as? String else{
                print("no candidate")
                return
            }
            
            let data = candidateStr.data(using: String.Encoding.utf8)!
            let candidate = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            
            self.callbacks.onReceiveCandidate(targetId, candidate)
        }
        
        session.subscribe(callmeTopic(), onSuccess: { (subscription) in
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
        
        session.subscribe(closeTopic(), onSuccess: { (subscription) in
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
    
    // MARK: SwampSessionDelegate
    
    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String{
        return SwampCraAuthHelper.sign("secret123", challenge: extra["challenge"] as! String)
    }
    
    func swampSessionConnected(_ session: SwampSession, sessionId: Int){
        self.session = session
        onConnect()
    }
    
    func swampSessionEnded(_ reason: String){
        print("swampSessionEnded: \(reason)")
    }
    
    static let HandshakeEndpint = "wss://nakadoribooks-webrtc.herokuapp.com"
    
    private func roomTopic(base:String)->String{
        return base.replacingOccurrences(of: "[roomId]", with: self.roomId)
    }
    
    func answerTopic(userId:String)->String{
        return self.roomTopic(base: WampTopic.answer.rawValue.replacingOccurrences(of: "[userId]", with: userId))
    }
    
    func offerTopic(userId:String)->String{
        return self.roomTopic(base: WampTopic.offer.rawValue.replacingOccurrences(of: "[userId]", with: userId))
    }
    
    func candidateTopic(userId:String)->String{
        return self.roomTopic(base: WampTopic.candidate.rawValue.replacingOccurrences(of: "[userId]", with: userId))
    }
    
    func callmeTopic()->String{
        return self.roomTopic(base: WampTopic.callme.rawValue)
    }
    
    func closeTopic()->String{
        return self.roomTopic(base: WampTopic.close.rawValue)
    }
    
}
