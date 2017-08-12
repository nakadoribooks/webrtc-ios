//
//  WampInterface.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

protocol WampInterface {
    
    func connect()
    func publishCallme()
    func publishOffer(targetId:String ,sdp:String)
    func publishAnswer(targetId:String, sdp:String)
    func publishCandidate(targetId:String, candidate:String)
    
}
