//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

typealias WebRTCOnCreateOfferHandler = (_ sdp:NSDictionary) -> ()
typealias WebRTCOnCreateAnswerHandler = (_ sdp:NSDictionary) -> ()
typealias WebRTCOnIceCandidateHandler = (_ candidate:NSDictionary) -> ()
typealias WebRTCOnAddedStream = (_ stream:RTCMediaStream) -> ()
typealias WebRTCOnRemoveStream = (_ stream:RTCMediaStream) -> ()
typealias WebRTCCallbacks = (onCreateOffer:WebRTCOnCreateOfferHandler
    , onCreateAnswer:WebRTCOnCreateAnswerHandler
    , onIceCandidate:WebRTCOnIceCandidateHandler
    , onAddedStream:WebRTCOnAddedStream
    , onRemoveStream:WebRTCOnRemoveStream)

class WebRTC: NSObject, RTCPeerConnectionDelegate {
    
    // MARK: static -----
    
    private static let IceServerUrls = ["stun:stun.l.google.com:19302"]
    private static let factory = RTCPeerConnectionFactory()
    private static var _localStream:RTCMediaStream?
    
    static func setup(){
        let streamId = WebRTCUtil.idWithPrefix(prefix: "stream")
        _localStream = factory.mediaStream(withStreamId: streamId)
        
        setupLocalVideoTrack()
        setupLocalAudioTrack()
    }
    
    static func disableVideo(){
        _localStream?.videoTracks.first?.isEnabled = false
    }
    
    static func enableVideo(){
        _localStream?.videoTracks.first?.isEnabled = true
    }
    
    static var localStream:RTCMediaStream?{
        get{
            return _localStream
        }
    }
    
    private static func setupLocalVideoTrack(){
        let localVideoSource = factory.avFoundationVideoSource(with: WebRTCUtil.mediaStreamConstraints())
        let localVideoTrack = factory.videoTrack(with: localVideoSource, trackId: WebRTCUtil.idWithPrefix(prefix: "video"))
        
        if let avSource = localVideoTrack.source as? RTCAVFoundationVideoSource{
            avSource.useBackCamera = true
        }
        
        _localStream?.addVideoTrack(localVideoTrack)
    }
    
    private static func setupLocalAudioTrack(){
        let localAudioTrack = factory.audioTrack(withTrackId: WebRTCUtil.idWithPrefix(prefix: "audio"))
        _localStream?.addAudioTrack(localAudioTrack)
    }
    
    // MARK: instance ------
    
    private var remoteStream:RTCMediaStream?
    private var peerConnection:RTCPeerConnection?
    private let callbacks:WebRTCCallbacks
    
    init(callbacks:WebRTCCallbacks){
        self.callbacks = callbacks
        super.init()
        
        setupPeerConnection()
    }
    
    private func setupPeerConnection(){
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: WebRTC.IceServerUrls)]
        peerConnection = WebRTC.factory.peerConnection(with: configuration, constraints: WebRTCUtil.peerConnectionConstraints(), delegate: self)
        peerConnection?.add(WebRTC.localStream!)
    }
    
    // MARK: inteface ------
    
    func receiveCandidate(candidate:NSDictionary){
        guard let candidate = candidate as? [AnyHashable:Any]
            , let sdp = candidate["candidate"] as? String
            , let sdpMLineIndex = candidate["sdpMLineIndex"] as? Int32
            , let sdpMid = candidate["sdpMid"] as? String else{
                
                print("invalid candiate")
            return
        }
        
        let rtcCandidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
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
    
    func receiveOffer(remoteSdp:NSDictionary){
        
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
                    
                    self.callbacks.onCreateAnswer(localDescription)
                })
                
            })
        })
    }
    
    func createOffer(){
        
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
                
                self.callbacks.onCreateOffer(localDescription)
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
        DispatchQueue.main.async {
            self.callbacks.onAddedStream(stream)
        }
    }
    
}
