//
//  RemoteRenderView.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class RemoteRenderView: NSObject, RTCEAGLVideoViewDelegate {
    
    static let Margin:CGFloat = 20.0
    static let ViewSize:CGFloat = (windowWidth() - (Margin * 3)) / 2.0

    let targetId:String
    let view = UIView(frame: CGRect(x: 0, y: 0, width: ViewSize, height: ViewSize))
    private let stream:RTCMediaStream
    private let renderView = RTCEAGLVideoView()
    
    init(stream:RTCMediaStream, targetId:String){
        self.stream = stream
        self.targetId = targetId
        super.init()
        
        if let remoteVideoTrack =  stream.videoTracks.first {
            remoteVideoTrack.add(renderView)
        }
        
        renderView.delegate = self
        setupView()
    }
    
    func setupView(){
        view.clipsToBounds = true
        view.addSubview(renderView)
        
        let overlay = UIView()
        overlay.frame.size = view.frame.size
        view.addSubview(overlay)
        
        let labelBg = UIView()
        labelBg.frame = CGRect(x: 0, y: view.frame.size.height - 30, width: view.frame.size.width, height: 30)
        labelBg.backgroundColor = UIColor.white
        labelBg.alpha = 0.8
        overlay.addSubview(labelBg)
        
        let label = UILabel()
        label.frame = CGRect(x: 0, y: view.frame.size.height - 30, width: view.frame.size.width, height: 30)
        label.textAlignment = .center
        label.text = targetId
        label.textColor = UIColor.black
        overlay.addSubview(label)
    }
    
    // MARK: RTCEAGLVideoViewDelegate
    
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        
        let ratio:CGFloat = size.width / size.height
        
        if ratio > 1.0{
            // 横長
            let height:CGFloat = RemoteRenderView.ViewSize
            let width:CGFloat = height * ratio
            let x:CGFloat = (RemoteRenderView.ViewSize - width) / 2.0
            renderView.frame = CGRect(x: x, y: 0, width: width, height: height)
        }else{
            // 縦長
            let width:CGFloat = RemoteRenderView.ViewSize
            let height:CGFloat = width / max(ratio, 0.1)
            let y:CGFloat = (RemoteRenderView.ViewSize - height) / 2.0
            renderView.frame = CGRect(x: 0, y: y, width: width, height: height)
        }
    }

}
