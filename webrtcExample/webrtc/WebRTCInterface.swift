//
//  WebRTCInterface.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias WebRTCOnCreateOfferHandler = (_ sdp:String) -> ()
typealias WebRTCOnCreateAnswerHandler = (_ sdp:String) -> ()
typealias WebRTCOnIceCandidateHandler = (_ sdp:String, _ sdpMid:String, _ sdpMLineIndex:Int32) -> ()
typealias WebRTCOnAddedStream = (_ stream:RTCMediaStream) -> ()
typealias WebRTCOnRemoveStream = (_ stream:RTCMediaStream) -> ()

typealias WebRTCCallback = (onCreateOffer:WebRTCOnCreateOfferHandler
    , onCreateAnswer:WebRTCOnCreateAnswerHandler
    , onIceCandidate:WebRTCOnIceCandidateHandler
    , onAddedStream:WebRTCOnAddedStream
    , onRemoveStream:WebRTCOnRemoveStream)

protocol WebRTCInterface {

    static func setup()
    static func disableVideo()
    static func enableVideo()
    static var localStream:RTCMediaStream?{ get }
    
    init(callbacks:WebRTCCallback)
    func createOffer()
    func receiveOffer(sdp:String)
    func receiveAnswer(sdp:String)
    func receiveCandidate(sdp:String, sdpMid:String, sdpMLineIndex:Int32)
    func close()
    
}
