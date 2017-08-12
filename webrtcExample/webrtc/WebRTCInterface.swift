//
//  WebRTCInterface.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

protocol WebRTCInterface {

    static func setup()
    static func disableVideo()
    static func enableVideo()
    static var localStream:RTCMediaStream?{ get }
    
    func receiveCandidate(candidate:NSDictionary)
    func receiveAnswer(remoteSdp:NSDictionary)
    func receiveOffer(remoteSdp:NSDictionary)
    func createOffer()
    func close()
    
}
