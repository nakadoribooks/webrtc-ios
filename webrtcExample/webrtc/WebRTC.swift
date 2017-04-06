//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class WebRTC: NSObject, RTCPeerConnectionDelegate, RTCEAGLVideoViewDelegate {

    private var didGenerateCandidate:((_ candidate:NSDictionary)->())?

    private var didReceiveRemoteStream:(()->())?
    private var onCreatedLocalSdp:((_ localSdp:NSDictionary)->())?
    
    private let factory = RTCPeerConnectionFactory()
    
    private var localStream:RTCMediaStream?
    private var localRenderView = RTCEAGLVideoView()
    private let _localView = UIView(frame:CGRect(x:0, y:0, width:windowWidth()/3, height:windowWidth()/3))
    
    private var remoteStream:RTCMediaStream?
    private var remoteRenderView = RTCEAGLVideoView()
    private let _remoteView = UIView(frame: CGRect(x: 0, y: 0, width: windowWidth(), height: windowWidth()))
    
    private var peerConnection:RTCPeerConnection?
    
    static let sharedInstance = WebRTC()
    
    private override init() {
        super.init()
    }
    
    // MARK: inerface
    
    func localView()->UIView{
        return _localView
    }
    
    func remoteView()->UIView{
        return _remoteView
    }
    
    func setup(){
        setupLocalStream()
    }
    
    func connect(iceServerUrlList:[String]
        , onCreatedLocalSdp:@escaping ((_ localSdp:NSDictionary)->())
        , didGenerateCandidate:@escaping ((_ localSdp:NSDictionary)->())
        , didReceiveRemoteStream:@escaping (()->())){
        self.onCreatedLocalSdp = onCreatedLocalSdp
        self.didGenerateCandidate = didGenerateCandidate
        self.didReceiveRemoteStream = didReceiveRemoteStream
        
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: iceServerUrlList)]
        peerConnection = factory.peerConnection(with: configuration, constraints: WebRTCUtil.peerConnectionConstraints(), delegate: self)
        peerConnection?.add(localStream!)
    }
    
    // Answer の受け取り
    func receiveAnswer(remoteSdp:NSDictionary){
        _receiveAnswer(remoteSdp: remoteSdp)
    }
    
    // Offerの受け取り
    func receiveOffer(remoteSdp:NSDictionary){
        _receiveOffer(remoteSdp: remoteSdp)
    }
    
    func receiveCandidate(candidate:NSDictionary){
        guard let candidate = candidate as? [AnyHashable:Any]
            , let rtcCandidate = RTCIceCandidate(fromJSONDictionary: candidate) else{
            print("invalid candiate")
            return
        }
        
        self.peerConnection?.add(rtcCandidate)
    }
    
    // Offerを作る

    func createOffer(){
        _createOffer()
    }
    
    // MARK: implements
    
    private func _receiveAnswer(remoteSdp:NSDictionary){
        
        guard let sdpContents = remoteSdp.object(forKey: "sdp") as? String else{
            print("noSDp")
            return;
        }
        
        let sdp = RTCSessionDescription(type: .answer, sdp: sdpContents)
        
        // 1. remote SDP を登録
        peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in
            
        })
    }
    
    private func _receiveOffer(remoteSdp:NSDictionary){
        
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
                    guard let callback = self.onCreatedLocalSdp, let localDescription = WebRTCUtil.jsonFromDescription(description: self.peerConnection?.localDescription) else{
                        print("no localDescription")
                        return ;
                    }
                    
                    callback(localDescription)
                    self.onCreatedLocalSdp = nil
                })
                
            })
        })
    }
    
    private func _createOffer(){
        
        // 1. offerを作る
        peerConnection?.offer(for: WebRTCUtil.mediaStreamConstraints(), completionHandler: { (description, error) in
            
            guard let description = description else{
                print("----- no description ----")
                return;
            }
            
            // 2.ローカルにSDPを登録
            self.peerConnection?.setLocalDescription(description, completionHandler: { (error) in
                
            })
            
            // 3. offer を送る
            guard let callback = self.onCreatedLocalSdp, let localDescription = WebRTCUtil.jsonFromDescription(description: self.peerConnection?.localDescription) else{
                print("no localDescription")
                return ;
            }
    
            callback(localDescription)
            self.onCreatedLocalSdp = nil
            
        })
    }
    
    private func setupLocalStream(){
        
        let streamId = WebRTCUtil.idWithPrefix(prefix: "stream")
        localStream = factory.mediaStream(withStreamId: streamId)
        
        setupView()
        
        setupLocalVideoTrack()
        setupLocalAudioTrack()
    }
    
    private func setupView(){
        
        localRenderView.delegate = self
        _localView.backgroundColor = UIColor.white
        _localView.frame.origin = CGPoint(x: 20, y: _remoteView.frame.size.height - (_localView.frame.size.height / 2))
        _localView.addSubview(localRenderView)
        
        remoteRenderView.delegate = self
        _remoteView.backgroundColor = UIColor.lightGray
        _remoteView.addSubview(remoteRenderView)
    }
    
    private func setupLocalVideoTrack(){
        let localVideoSource = factory.avFoundationVideoSource(with: WebRTCUtil.mediaStreamConstraints())
        let localVideoTrack = factory.videoTrack(with: localVideoSource, trackId: WebRTCUtil.idWithPrefix(prefix: "video"))
        
        if let avSource = localVideoTrack.source as? RTCAVFoundationVideoSource{
            avSource.useBackCamera = true
        }
        
        localVideoTrack.add(localRenderView)
        localStream?.addVideoTrack(localVideoTrack)
    }
    
    private func setupLocalAudioTrack(){
        let localAudioTrack = factory.audioTrack(withTrackId: WebRTCUtil.idWithPrefix(prefix: "audio"))
        localStream?.addAudioTrack(localAudioTrack)
    }
    
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
        print("didGenerate candidate")
        
        if let didGenerateCandidate = self.didGenerateCandidate, let candidateJson = WebRTCUtil.jsonFromData(data: candidate.jsonData()){
            print("didGenerateCandidate")
            didGenerateCandidate(candidateJson)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream){
        print("peerConnection didAdd stream:")
        
        if stream == localStream{
            return;
        }
        
        self.remoteStream = stream
        
        if let remoteVideoTrack =  stream.videoTracks.first {
            remoteVideoTrack.add(remoteRenderView)
        }
        
        if let callback = self.didReceiveRemoteStream{
            DispatchQueue.main.async {
                callback()
            }
            self.didReceiveRemoteStream = nil
        }
    }
    
    // MARK: RTCEAGLVideoViewDelegate
    
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        print("---- didChangeVideoSize -----")
        
        let ratio:CGFloat = size.width / size.height
        
        if videoView == localRenderView{
            let parentWidth = _localView.frame.size.width
            let width = parentWidth * ratio
            localRenderView.frame = CGRect(x: (parentWidth - width) / 2, y: 2, width: width, height: _localView.frame.size.height-4)
        }else if videoView == remoteRenderView{
            let parentWidth = _remoteView.frame.size.width
            let width = parentWidth * ratio
            remoteRenderView.frame = CGRect(x: (parentWidth - width) / 2, y: 0, width: width, height: _remoteView.frame.size.height)
        }
    }
    
}
