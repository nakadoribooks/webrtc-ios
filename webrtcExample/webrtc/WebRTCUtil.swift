//
//  WebRTCUtil.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class WebRTCUtil: NSObject {

    static func idWithPrefix(prefix:String)->String{
        return "\(prefix)_\(randomStringWithLength(len: 20))"
    }
    
    static func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0..<len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString
    }
    
    static func mediaStreamConstraints()->RTCMediaConstraints{
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    }
    
    static func jsonFromDescription(description:RTCSessionDescription?)->NSDictionary?{
        guard let description = description else{
            print("description is nil")
            return nil
        }
        
        return jsonFromData(data: description.jsonData())
    }
    
    static func jsonFromCandidate(candidate:RTCIceCandidate)->NSDictionary?{
        return jsonFromData(data: candidate.jsonData())
    }
    
    static func jsonFromData(data:Data)->NSDictionary?{
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        
        guard let result = json as? NSDictionary else{
            return nil
        }
        
        return result
    }

    
}
