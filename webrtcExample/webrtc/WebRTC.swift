//
//  WebRTC.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

class WebRTC: NSObject, RTCPeerConnectionDelegate {

    private let factory = RTCPeerConnectionFactory()
    private var localRenderView = RTCEAGLVideoView()
    private var localStream:RTCMediaStream?
    private let _localView = UIView(frame:CGRect(x:20, y:40, width:140, height:200))
    private var peerConnection:RTCPeerConnection?
    
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
    
    func connect(iceServerUrlList:[String]){
        print("--- connect ----")
        
        let configuration = RTCConfiguration()
        
        configuration.iceServers = [RTCIceServer(urlStrings: iceServerUrlList)]
        peerConnection = factory.peerConnection(with: configuration, constraints: peerConnectionConstraints(), delegate: self)
        peerConnection?.add(localStream!)
    }
    
    func createOffer(){
        
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
    
    private func answerConstraints()->RTCMediaConstraints{
        return offerConstraints()
    }
    
    private func offerConstraints()->RTCMediaConstraints{
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo":"true"]
        return RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
    }
    
    private func mediaStreamConstraints()->RTCMediaConstraints{
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    }
    
    private func peerConnectionConstraints()->RTCMediaConstraints {
        
        let optionalConstraints = ["DtlsSrtpKeyAgreement":"true"]
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
        
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
