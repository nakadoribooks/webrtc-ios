//
//  ConnectionInterface.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

protocol ConnectionInterface{

    var remoteStream:RTCMediaStream?{ get }
    var targetId:String?{ get }
    func receiveOffer(offerSdp:NSDictionary)
    func publishOffer()
    func receiveAnswer(sdp:NSDictionary)
    func receiveCandidate(candidate:NSDictionary)
    func close()
    
}
