//
//  ViewController.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit

extension String {
    static func getRandomStringWithLength(length: Int) -> String {
        
        let alphabet = "1234567890abcdefghijklmnopqrstuvwxyz"
        let upperBound = UInt32(alphabet.characters.count)
        
        return String((0..<length).map { _ -> Character in
            return alphabet[alphabet.index(alphabet.startIndex, offsetBy: Int(arc4random_uniform(upperBound)))]
        })
    }
}

class ViewController: UIViewController {

    private var wamp:WampInterface!
    private var connectionList:[ConnectionInterface] = []
    private var remoteRenderList:[RemoteRenderView] = []
    
    private let remoteLayer = UIView(frame: windowFrame())
    private let localLayer = UIView(frame: CGRect(x: 0, y: windowHeight() - LocalRenderView.Size.height - 20, width: windowWidth(), height: LocalRenderView.Size.height + 20))
    private var roomId:String!
    private let userId = String.getRandomStringWithLength(length: 8)
    private let toggleButton = UIButton()
    
    deinit {
        print("ViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        setupRoom()
        setupWamp()
        setupStream()
        
        wamp.connect()
        
        view.addSubview(remoteLayer)
        view.addSubview(localLayer)
        
        setupLocalView()
    }
    
    private func setupLocalView(){
        localLayer.backgroundColor = UIColor.gray
        let localRenderView = LocalRenderView(stream: WebRTC.localStream!, targetId: userId)
        localRenderView.view.frame.origin = CGPoint(x: 10, y: 10)
        localLayer.addSubview(localRenderView.view)
        
        let labelX = LocalRenderView.Size.width + 20.0
        let labelWidth = windowWidth() - labelX - 10
        let label = UILabel(frame: CGRect(x: labelX, y: 10, width: labelWidth, height: 50))
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.textColor = UIColor.white
        label.text = "You\n(\(self.userId))"
        label.sizeToFit()
        localLayer.addSubview(label)
        
        let y:CGFloat = label.frame.size.height + 20
        
        toggleButton.frame = CGRect(x: labelX, y: y, width: labelWidth, height: 44)
        toggleButton.backgroundColor = UIColor.white
        toggleButton.layer.cornerRadius = 5
        toggleButton.clipsToBounds = true
        toggleButton.setTitleColor(UIColor.gray, for: .normal)
        toggleButton.setTitle("Stop", for: .normal)
        toggleButton.setTitle("Play", for: .selected)
        toggleButton.addTarget(self, action: #selector(ViewController.tapToggle), for: .touchUpInside)
        localLayer.addSubview(toggleButton)
    }
    
    private dynamic func tapToggle(){
        
        print("tap")
        
        toggleButton.isSelected = !toggleButton.isSelected
        
        let active = !toggleButton.isSelected
        if active{
            WebRTC.enableVideo()
        }else{
            WebRTC.disableVideo()
        }
    }
    
    private func setupStream(){
        WebRTC.setup()
    }
    
    private func setupRoom(){
        let roomId:String? = "abcdef"
        
        if let roomId = roomId{
            self.roomId = roomId
            return
        }
        
        self.roomId = String.getRandomStringWithLength(length: 8)        
        print("roomId:\(roomId)")
    }
    
    private func setupWamp(){
        
        let wamp = Wamp(roomId: roomId, userId: userId
        , callbacks: (
            onOpen:{() -> Void in
                print("onOpen")
                
                self.wamp.publishCallme()
            }
            , onReceiveOffer:{(targetId:String, sdp:String) -> Void in
                print("onReceiveOffer")
                
                let connection = self.createConnection(targetId: targetId)
                connection.receiveOffer(sdp: sdp)
            }
            , onReceiveAnswer:{(targetId:String, sdp:String) -> Void in
                print("onReceiveAnswer")
                
                guard let connection = self.findConnection(targetId: targetId) else{
                    return
                }
                
                connection.receiveAnswer(sdp: sdp)
            }
            , onReceiveCandidate:{(targetId:String, sdp:String, sdpMid:String, sdpMLineIndex:Int32) -> Void in
                guard let connection = self.findConnection(targetId: targetId) else{
                    return
                }
                
                connection.receiveCandidate(sdp: sdp, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
            }
            , onReceiveCallme:{(targetId:String) -> Void in
                print("onReceivCallme")
                let connection = self.createConnection(targetId:targetId)
                connection.publishOffer()
            }
            , onCloseConnection:{(targetId:String) -> Void in
                print("onCloseConnection")
                
                // removeConnection
                guard let removeIndex = self.connectionList.index(where: { (row) -> Bool in
                    return row.targetId == targetId
                }) else{
                    return
                }
                
                let connection = self.connectionList.remove(at: removeIndex)
                connection.close()
                
                // removeView
                guard let streamIndex = self.remoteRenderList.index(where: { (row) -> Bool in
                    return row.targetId == targetId
                }) else{
                    return;
                }
                
                let remoteRender = self.remoteRenderList.remove(at: streamIndex)
                remoteRender.view.removeFromSuperview()
                
                self.calcRemoteViewPosition()
            }
       ))
        
        self.wamp = wamp
    }
    
    private func createConnection(targetId:String)->Connection{
        let connection = Connection(myId: userId, targetId: targetId, wamp: wamp) { (remoteStream) in
            print("onAeedStream")
            
            let remoteRenderView = RemoteRenderView(stream: remoteStream, targetId: targetId)
            self.remoteLayer.addSubview(remoteRenderView.view)
            self.remoteRenderList.append(remoteRenderView)

            self.calcRemoteViewPosition()
        }
        connectionList.append(connection)
        return connection
    }
    
    private func findConnection(targetId:String)->ConnectionInterface?{
        for i in 0..<connectionList.count{
            let connection = connectionList[i]
            if(connection.targetId == targetId){
                return connection
            }
        }
        
        print("not found connection")
        return nil
    }
    
    private func calcRemoteViewPosition(){
        var y:CGFloat = 20.0
        var x:CGFloat = 20
        
        for i in 0..<remoteRenderList.count{
            let view = remoteRenderList[i].view
            view.frame.origin = CGPoint(x: x, y: y)
            
            if x + view.frame.size.width > windowWidth(){
                x = 20
                y = y + view.frame.size.height
                view.frame.origin = CGPoint(x: x, y: y)
            }
            x = x + view.frame.size.width + 20
        }
    }

}

