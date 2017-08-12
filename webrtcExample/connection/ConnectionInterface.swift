//
//  ConnectionInterface.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias ConnectionOnAddedStream = (_ stream:RTCMediaStream)->()

protocol ConnectionInterface{

    init(myId:String, targetId:String, wamp:WampInterface, onAddedStream:@escaping ConnectionOnAddedStream)
    var targetId:String?{ get }
    func publishOffer()
    func receiveOffer(sdp:String)
    func receiveAnswer(sdp:String)
    func receiveCandidate(sdp:String, sdpMid:String, sdpMLineIndex:Int32)
    func close()
    
}
