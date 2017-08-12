//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class WebRTC: NSObject, WebRTCInterface, RTCPeerConnectionDelegate {
    
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
    private let callbacks:WebRTCCallback
    
    required init(callbacks:WebRTCCallback){
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
    
    func receiveCandidate(sdp:String, sdpMid:String, sdpMLineIndex:Int32){
        let rtcCandidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        self.peerConnection?.add(rtcCandidate)
    }
    
    func receiveAnswer(sdp:String){
        let sdp = RTCSessionDescription(type: .answer, sdp: sdp)
        
        // 1. remote SDP を登録
        peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in

        })
    }
    
    func receiveOffer(sdp:String){
        // 1. remote SDP を登録
        let remoteSdp = RTCSessionDescription(type: .offer, sdp: sdp)
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
                    guard let description = self.peerConnection?.localDescription else{
                        return;
                    }
                    
                    let dic:NSDictionary = [
                        "type": RTCSessionDescription.string(for: description.type)
                        , "sdp": description.sdp
                    ]
                    
                    do{
                        let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
                        let sdp = String(bytes: jsonData, encoding: .utf8)!
                        self.callbacks.onCreateAnswer(sdp)
                    }catch let e{
                        print(e)
                        return
                    }                    
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
                guard let description = self.peerConnection?.localDescription else{
                    return;
                }
                
                let dic:NSDictionary = [
                    "type": RTCSessionDescription.string(for: description.type)
                    , "sdp": description.sdp
                ]
                
                do{
                    let jsonData = try JSONSerialization.data(withJSONObject: dic, options: [])
                    let sdp = String(bytes: jsonData, encoding: .utf8)!
                    self.callbacks.onCreateOffer(sdp)
                }catch let e{
                    print(e)
                    return
                }
                
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
        if let sdpMid = candidate.sdpMid{
            self.callbacks.onIceCandidate(candidate.sdp, sdpMid, candidate.sdpMLineIndex)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream){
        DispatchQueue.main.async {
            self.callbacks.onAddedStream(stream)
        }
    }
    
}
