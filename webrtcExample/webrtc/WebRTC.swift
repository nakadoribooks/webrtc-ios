//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

protocol WebRTCDelegate:class {
    func didAddedRemoteStream()
    func onCreatedAnswer(sdp:NSDictionary)
}

class WebRTC: NSObject, RTCPeerConnectionDelegate {

    var delegate:WebRTCDelegate?
    private var createdOfferCallback:((_ sdp:NSDictionary)->())?
    private let factory = RTCPeerConnectionFactory()
    private var localStream:RTCMediaStream?
    
    private var localRenderView = RTCEAGLVideoView()
    private let _localView = UIView(frame:CGRect(x:20, y:40, width:140, height:200))
    
    private var remoteRenderView = RTCEAGLVideoView()
    private let _remoteView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 375))
    
    private var peerConnection:RTCPeerConnection?
    private var remoteStream:RTCMediaStream?
    
    static let sharedInstance = WebRTC()
    
    private override init() {
        super.init()
    }
    
    // MARK: public
    
    func localView()->UIView{
        return _localView
    }
    
    func remoteView()->UIView{
        return _remoteView
    }
    
    func setup(){
        print("setup")
        
        setupLocalStream()
    }
    
    func connect(iceServerUrlList:[String]){
        print("--- connect ----")
        
        let configuration = RTCConfiguration()
        
        configuration.iceServers = [RTCIceServer(urlStrings: iceServerUrlList)]
        peerConnection = factory.peerConnection(with: configuration, constraints: peerConnectionConstraints(), delegate: self)
        peerConnection?.add(localStream!)
    }
    
    func receiveAnswer(remoteSdp:NSDictionary){
        
        print("receiveAnswer")
        
        guard let sdpContents = remoteSdp.object(forKey: "sdp") as? String else{
            print("noSDp")
            return;
        }
        
        let sdp = RTCSessionDescription(type: .answer, sdp: sdpContents)
        
        peerConnection?.setRemoteDescription(sdp, completionHandler: { (error) in
            if let error = error{
                print("error")
                print(error)
                return;
            }
            
            print("setted remoteDescription")
        })
    }
    
    func receiveOffer(remoteSdp:NSDictionary){
        print("receiveOffer")
        print(remoteSdp)
        
        guard let sdpContents = remoteSdp.object(forKey: "sdp") as? String else{
            print("noSDp")
            return;
        }
        
        let remoteSdp = RTCSessionDescription(type: .offer, sdp: sdpContents)
        peerConnection?.setRemoteDescription(remoteSdp, completionHandler: { (error) in
            if let error = error{
                print("error")
                print(error)
                return;
            }
            
            print("setted remoteDescription")
            self.peerConnection?.answer(for: self.answerConstraints(), completionHandler: { (sdp, error) in
                if let error = error{
                    print("fail answer")
                    print(error)
                    return;
                }
                
                guard let sdp = sdp else{
                    print("can not create sdp")
                    return;
                }
                
                self.peerConnection?.setLocalDescription(sdp, completionHandler: { (error) in
                    if let error = error{
                        print("fail setLocalDescription")
                        return;
                    }
                    
                    guard let jsonSdp = WebRTCUtil.jsonFromDescription(description: sdp) else{
                        print(" fail answer no sdp")
                        return;
                    }
                    
                    print("createdAnswer")
                    self.delegate?.onCreatedAnswer(sdp: jsonSdp)
                })
            })
        })
    }
    
    func createOffer(callback:@escaping (_ sdp:NSDictionary)->()){
        self.createdOfferCallback = callback
        print("createOffer")
        
        peerConnection?.offer(for: mediaStreamConstraints(), completionHandler: { (description, error) in
            if let error = error{
                print("fail offer")
                print(error)
                return;
            }
            
            guard let description = description, let jsonDescription = WebRTCUtil.jsonFromDescription(description: description) else{
                print("----- no description ----")
                return;
            }
            
            self.peerConnection?.setLocalDescription(description, completionHandler: { (error) in
                if let error = error{
                    print("fail setLocalDescription")
                    print(error)
                    return;
                }
                
                print("success setLocalDescription")
                
            })
        })
    }
    
    // MARK: private
    
    private func setupLocalStream(){
        
        let streamId = WebRTCUtil.idWithPrefix(prefix: "stream")
        localStream = factory.mediaStream(withStreamId: streamId)
        
        setupView()
        
        setupLocalVideoTrack()
        setupLocalAudioTrack()
    }
    
    private func setupView(){
        localRenderView.frame.size = _localView.frame.size
        _localView.addSubview(localRenderView)
        
        remoteRenderView.frame.size = _remoteView.frame.size
        _remoteView.addSubview(remoteRenderView)
    }
    
    private func setupLocalVideoTrack(){
        let localVideoSource = factory.avFoundationVideoSource(with: WebRTCUtil.mediaStreamConstraints())
        let localVideoTrack = factory.videoTrack(with: localVideoSource, trackId: WebRTCUtil.idWithPrefix(prefix: "video"))
        
        localVideoTrack.add(localRenderView)
        localStream?.addVideoTrack(localVideoTrack)
    }
    
    private func setupLocalAudioTrack(){
        let localAudioTrack = factory.audioTrack(withTrackId: WebRTCUtil.idWithPrefix(prefix: "audio"))
        localStream?.addAudioTrack(localAudioTrack)
    }
    
    private func answerConstraints()->RTCMediaConstraints{
        return offerConstraints()
    }
    
    private func offerConstraints()->RTCMediaConstraints{
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveVideo": kRTCMediaConstraintsValueTrue,
                                   "OfferToReceiveAudio": kRTCMediaConstraintsValueTrue],
            optionalConstraints: nil)
        
        return constraints
    }
    
    private func mediaStreamConstraints()->RTCMediaConstraints{
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["kRTCMediaConstraintsMaxFrameRate": "30",
                                   "kRTCMediaConstraintsMinFrameRate": "30"],
            optionalConstraints: nil)
        
        return constraints
        
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    }
    
    private func peerConnectionConstraints()->RTCMediaConstraints {
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveVideo": kRTCMediaConstraintsValueTrue,
                                   "OfferToReceiveAudio": kRTCMediaConstraintsValueTrue],
            optionalConstraints: nil)
        
        return constraints
    }
    
    // MARK: RTCPeerConnectionDelegate
    
    
    /** Called when the SignalingState changed. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState){
        print("peerConnection didChange stateChanged")
    }
    
    /** Called when media is received on a new stream from remote peer. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream){
        print("peerConnection didAdd stream:")
        
        remoteStream = stream
        
        if let remoteVideoTrack =  stream.videoTracks.first {
            print("find remoteVideoTrack, \(remoteVideoTrack.isEnabled)")
            remoteVideoTrack.add(remoteRenderView)
        }
        
        delegate?.didAddedRemoteStream()
    }
    
    /** Called when a remote peer closes a stream. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream){
        print("peerConnection didRemove stream")
    }
    
    /** Called when negotiation is needed, for example ICE has restarted. */
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection){
        print("peerConnectionShouldNegotiate")
    }
    
    /** Called any time the IceConnectionState changes. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState){
        print("peerConnection didChange newState: RTCIceConnectionState")
    }
    
    
    /** Called any time the IceGatheringState changes. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState){
        print("peerConnection didChange newState: RTCIceGatheringState, \(newState)")
        
        switch newState {
        case .complete:
            print(".complete")
            
            guard let callback = self.createdOfferCallback, let localDescription = WebRTCUtil.jsonFromDescription(description: self.peerConnection?.localDescription) else{
                print("no localDescription")
                return ;
            }
            
            callback(localDescription)
            
        case .gathering:
            print(".gathering")
        case .new:
            print(".new")
        }
    }
    
    /** New ice candidate has been found. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate){
        print("peerConnection didGenerate candidate: RTCIceCandidate")
        
        guard let jsonCandidate = WebRTCUtil.jsonFromData(data: candidate.jsonData()) else{
            print("------------- no json candidate --------------")
            return;
        }
        
        print(jsonCandidate)
    }
    
    /** Called when a group of local Ice candidates have been removed. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]){
        print("peerConnection didRemove candidates")
    }
    
    
    /** New data channel has been opened. */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel){
        print("peerConnection didOpen dataChannel")
    }
    
}
