//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class WebRTC: NSObject {

    private let factory = RTCPeerConnectionFactory()
    private var localRenderView = RTCEAGLVideoView()
    private var localStream:RTCMediaStream?
    private let _localView = UIView(frame:CGRect(x:20, y:40, width:140, height:200))
    
    static let sharedInstance = WebRTC()
    
    private override init() {
        super.init()
    }
    
    // MARK: public
    
    func localView()->UIView{
        return _localView
    }
    
    func setup(){
        print("setup")
        
        setupLocalStream()
    }
    
    // MARK: private
    
    private func setupLocalStream(){
        
        let streamId = WebRTCUtil.idWithPrefix(prefix: "stream")
        localStream = factory.mediaStream(withStreamId: streamId)
        setupLocalVideoTrack()
    }
    
    private func setupLocalVideoTrack(){
        localRenderView.frame.size = _localView.frame.size
        _localView.addSubview(localRenderView)
        
        let localVideoSource = factory.avFoundationVideoSource(with: WebRTCUtil.mediaStreamConstraints())
        let localVideoTrack = factory.videoTrack(with: localVideoSource, trackId: WebRTCUtil.idWithPrefix(prefix: "video"))
        
        localVideoTrack.add(localRenderView)
        
        localStream?.addVideoTrack(localVideoTrack)
    }
    
}
