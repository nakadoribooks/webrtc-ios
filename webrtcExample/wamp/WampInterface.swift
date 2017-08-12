//
//  WampInterface.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias WampOnOpenHandler = (()->())
typealias WampReceiveAnswerHandler = ((_ targetId:String, _ sdp:String)->())
typealias WampReceiveOfferHandler = ((_ targetId:String, _ sdp:String)->())
typealias WampReceiveCandidateHandler = ((_ targetId:String, _ sdp:String, _ sdpMid:String, _ sdpMLineIndex:Int32)->())
typealias WampReceiveCallmeHandler = ((_ targetId:String)->())
typealias WampOncloseConnectionHandler = ((_ targetId:String)->())

typealias WampCallback = (onOpen:WampOnOpenHandler
    , onReceiveAnswer:WampReceiveAnswerHandler
    , onReceiveOffer:WampReceiveOfferHandler
    , onReceiveCallme:WampReceiveCallmeHandler
    , onCloseConnection:WampOncloseConnectionHandler
    , onReceiveCandidate:WampReceiveCandidateHandler)


protocol WampInterface {
    
    init(roomId:String, userId:String, callbacks:WampCallback)
    func connect()
    func publishCallme()
    func publishOffer(targetId:String ,sdp:String)
    func publishAnswer(targetId:String, sdp:String)
    func publishCandidate(targetId:String, candidate:String)
    
}
