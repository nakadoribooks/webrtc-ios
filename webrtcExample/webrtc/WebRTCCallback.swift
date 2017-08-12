//
//  WebRTCCallback.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias WebRTCOnCreateOfferHandler = (_ sdp:NSDictionary) -> ()
typealias WebRTCOnCreateAnswerHandler = (_ sdp:NSDictionary) -> ()
typealias WebRTCOnIceCandidateHandler = (_ candidate:NSDictionary) -> ()
typealias WebRTCOnAddedStream = (_ stream:RTCMediaStream) -> ()
typealias WebRTCOnRemoveStream = (_ stream:RTCMediaStream) -> ()

typealias WebRTCCallback = (onCreateOffer:WebRTCOnCreateOfferHandler
    , onCreateAnswer:WebRTCOnCreateAnswerHandler
    , onIceCandidate:WebRTCOnIceCandidateHandler
    , onAddedStream:WebRTCOnAddedStream
    , onRemoveStream:WebRTCOnRemoveStream)
