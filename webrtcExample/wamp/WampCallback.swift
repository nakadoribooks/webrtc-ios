//
//  WampCallback.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias WampOnOpenHandler = (()->())
typealias WampReceiveAnswerHandler = ((_ targetId:String, _ sdp:NSDictionary)->())
typealias WampReceiveOfferHandler = ((_ targetId:String, _ sdp:NSDictionary)->())
typealias WampReceiveCandidateHandler = ((_ targetId:String, _ candidate:NSDictionary)->())
typealias WampReceiveCallmeHandler = ((_ targetId:String)->())
typealias WampOncloseConnectionHandler = ((_ targetId:String)->())

typealias WampCallback = (onOpen:WampOnOpenHandler
    , onReceiveAnswer:WampReceiveAnswerHandler
    , onReceiveOffer:WampReceiveOfferHandler
    , onReceiveCallme:WampReceiveCallmeHandler
    , onCloseConnection:WampOncloseConnectionHandler
    , onReceiveCandidate:WampReceiveCandidateHandler)
