//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias WebRTCOnIceCandidateHandler = (_ candidate:NSDictionary) -> ()
typealias WebRTCOnAddedStream = (_ stream:RTCMediaStream, _ view:UIView) -> ()
typealias WebRTCOnRemoveStream = (_ stream:RTCMediaStream) -> ()
typealias WebRTCCallbacks = (onIceCandidate:WebRTCOnIceCandidateHandler, onAddedStream:WebRTCOnAddedStream, onRemoveStream:WebRTCOnRemoveStream)

class WebRTC: NSObject, RTCPeerConnectionDelegate, RTCEAGLVideoViewDelegate {
    
    // ▼ inner class -----
    class LocalViewDelegate:NSObject, RTCEAGLVideoViewDelegate{
        
        private let localRenderView:RTCEAGLVideoView
        
        init(localRenderView:RTCEAGLVideoView){
            self.localRenderView = localRenderView
            super.init()
            
            localRenderView.delegate = self
        }
        
        // MARK: RTCEAGLVideoViewDelegate
        
        func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
            print("---- didChangeVideoSize -----")
            
            let ratio:CGFloat = size.width / size.height
            
            let width:CGFloat = 200.0
            let height = width / ratio
            localRenderView.frame = CGRect(x: 0, y: 0, width: width, height: height)            
        }
    }
    
    // ▼ static -----
    
    private static let IceServerUrls = ["stun:stun.l.google.com:19302"]
    private static let factory = RTCPeerConnectionFactory()
    private static var localStream:RTCMediaStream?
    private static var localRenderView = RTCEAGLVideoView()
    private static let _localView = UIView(frame:CGRect(x:0, y:0, width:windowWidth()/3, height:windowWidth()/3))
    private static var localViewDelegate:LocalViewDelegate!
    static func setup(){
        let streamId = WebRTCUtil.idWithPrefix(prefix: "stream")
        localStream = factory.mediaStream(withStreamId: streamId)
        
        localViewDelegate = LocalViewDelegate(localRenderView: localRenderView)
        _localView.backgroundColor = UIColor.white
        _localView.frame.origin = CGPoint(x: 0, y: 0)
        _localView.addSubview(localRenderView)
        
        setupLocalVideoTrack()
        setupLocalAudioTrack()
    }
    
    static var localView:UIView{
        get{
            return _localView
        }
    }
    
    private static func setupLocalVideoTrack(){
        let localVideoSource = factory.avFoundationVideoSource(with: WebRTCUtil.mediaStreamConstraints())
        let localVideoTrack = factory.videoTrack(with: localVideoSource, trackId: WebRTCUtil.idWithPrefix(prefix: "video"))
        
        if let avSource = localVideoTrack.source as? RTCAVFoundationVideoSource{
            avSource.useBackCamera = true
        }
        
        localVideoTrack.add(localRenderView)
        localStream?.addVideoTrack(localVideoTrack)
    }
    
    private static func setupLocalAudioTrack(){
        let localAudioTrack = factory.audioTrack(withTrackId: WebRTCUtil.idWithPrefix(prefix: "audio"))
        localStream?.addAudioTrack(localAudioTrack)
    }
    
    // ▼ instance ------
    
    private var remoteStream:RTCMediaStream?
    private var remoteRenderView = RTCEAGLVideoView()
    private let _remoteView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    private var peerConnection:RTCPeerConnection?
    private let callbacks:WebRTCCallbacks
    
    init(callbacks:WebRTCCallbacks){
        self.callbacks = callbacks
        super.init()
        
        setupPeerConnection()
        
        remoteView.backgroundColor = UIColor.red
        remoteRenderView.backgroundColor = UIColor.blue
        remoteRenderView.delegate = self
        remoteView.addSubview(remoteRenderView)
    }
    
    private func setupPeerConnection(){
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: WebRTC.IceServerUrls)]
        peerConnection = WebRTC.factory.peerConnection(with: configuration, constraints: WebRTCUtil.peerConnectionConstraints(), delegate: self)
        peerConnection?.add(WebRTC.localStream!)
    }
    
    var remoteView:UIView{
        get{
            return _remoteView
        }
    }
    
    func receiveCandidate(candidate:NSDictionary){
        guard let candidate = candidate as? [AnyHashable:Any]
            , let rtcCandidate = RTCIceCandidate(fromJSONDictionary: candidate) else{
            print("invalid candiate")
            return
        }
        
        self.peerConnection?.add(rtcCandidate)
    }
    
    func receiveAnswer(remoteSdp:NSDictionary){
        
        guard let sdpContents = remoteSdp.object(forKey: "sdp") as? String else{
            print("noSDp")
            return;
        }
        
        let sdp = RTCSessionDescription(type: .answer, sdp: sdpContents)
        
        // 1. remote SDP を登録
        peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in

        })
    }
    
    func receiveOffer(remoteSdp:NSDictionary, callback:@escaping (_ answerSdp:NSDictionary)->()){
        
        guard let sdpContents = remoteSdp.object(forKey: "sdp") as? String else{
            print("noSDp")
            return;
        }
        
        // 1. remote SDP を登録
        let remoteSdp = RTCSessionDescription(type: .offer, sdp: sdpContents)
        peerConnection?.setRemoteDescription(remoteSdp, completionHandler: { (error) in

            // 2. answerを作る
            self.peerConnection?.answer(for: WebRTCUtil.answerConstraints(), completionHandler: { (sdp, error) in
                
                guard let sdp = sdp else{
                    print("can not create sdp")
                    return;
                }
                
                // 3.ローカルにSDPを登録
                self.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                    
                    // 3. answer を送る
                    guard let localDescription = WebRTCUtil.jsonFromDescription(description: self.peerConnection?.localDescription) else{
                        print("no localDescription")
                        return ;
                    }
                    
                    callback(localDescription)
                })
                
            })
        })
    }
    
    func createOffer(callback:@escaping (_ offerSdp:NSDictionary)->()){
        
        // 1. offerを作る
        peerConnection?.offer(for: WebRTCUtil.mediaStreamConstraints(), completionHandler: { (description, error) in
            
            guard let description = description else{
                print("----- no description ----")
                return;
            }
            
            // 2.ローカルにSDPを登録
            self.peerConnection?.setLocalDescription(description, completionHandler: { (error) in
                // 3. offer を送る
                guard let localDescription = WebRTCUtil.jsonFromDescription(description: self.peerConnection?.localDescription) else{
                    print("no localDescription")
                    return ;
                }
                
                callback(localDescription)
            })
        })
    }
    
    func close(){
        if let localStream = WebRTC.localStream{
            self.peerConnection?.remove(localStream)
        }
        
        self.peerConnection?.close()
        self.peerConnection = nil
    }
    
//    private func setupLocalStream(){
//        
//        let streamId = WebRTCUtil.idWithPrefix(prefix: "stream")
//        localStream = factory.mediaStream(withStreamId: streamId)
//        
//        setupView()
//        
//        setupLocalVideoTrack()
//        setupLocalAudioTrack()
//    }
    
    // MARK: RTCPeerConnectionDelegate
    
    // いったんスルー
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection){}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream){}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState){}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]){}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel){}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState){}
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState){}
    
    // for Trickle ice
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate){
        
        if let candidateJson = WebRTCUtil.jsonFromCandidate(candidate: candidate){
            self.callbacks.onIceCandidate(candidateJson)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream){
        
        self.remoteStream = stream
        if let remoteVideoTrack =  stream.videoTracks.first {
            remoteVideoTrack.add(remoteRenderView)
        }
        
        self.callbacks.onAddedStream(stream, remoteView)
    }
    
    // MARK: RTCEAGLVideoViewDelegate
    
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        
        let ratio:CGFloat = size.width / size.height
        
        let width:CGFloat = windowWidth() / 3 - 10
        let height = width / ratio
        remoteRenderView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        _remoteView.frame.size = remoteRenderView.frame.size
    }
    
}
