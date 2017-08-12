//
//  LocalRenderView.swift
//  webrtcExample
//
//  Created by 河瀬悠 on 2017/08/12.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class LocalRenderView: NSObject, RTCEAGLVideoViewDelegate {

    static let Margin:CGFloat = 20.0
    static let Size = CGSize(width: 100, height: 150)
    
    let view = UIView()
    
    private let stream:RTCMediaStream
    private let targetId:String
    private let renderView = RTCEAGLVideoView()
    
    init(stream:RTCMediaStream, targetId:String){
        self.stream = stream
        self.targetId = targetId
        super.init()
        view.frame.size = LocalRenderView.Size
        renderView.frame.size = view.frame.size
        view.backgroundColor = UIColor.black
        
        if let videoTrack =  stream.videoTracks.first {
            videoTrack.add(renderView)
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
            let height:CGFloat = view.frame.size.height
            let width:CGFloat = height * ratio
            let x:CGFloat = (view.frame.size.width - width) / 2.0
            renderView.frame = CGRect(x: x, y: 0, width: width, height: height)
        }else{
            // 縦長
            let width:CGFloat = view.frame.size.width
            let height:CGFloat = width / max(ratio, 0.1)
            let y:CGFloat = (view.frame.size.height - height) / 2.0
            renderView.frame = CGRect(x: 0, y: y, width: width, height: height)
        }
    }

}
