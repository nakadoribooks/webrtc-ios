//
//  ViewController.swift
//  webrtcExample
//
//  Created by kawase yu on 2017/04/01.
//  Copyright © 2017年 NakadoriBooks. All rights reserved.
//

import UIKit
import FirebaseDatabase

import UIKit

extension String {
    static func getRandomStringWithLength(length: Int) -> String {
        
        let alphabet = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let upperBound = UInt32(alphabet.characters.count)
        
        return String((0..<length).map { _ -> Character in
            return alphabet[alphabet.index(alphabet.startIndex, offsetBy: Int(arc4random_uniform(upperBound)))]
        })
    }
}

class ViewController: UIViewController {

    private let wamp = Wamp.sharedInstance
    private var connectionList:[Connection] = []
    private var streamWrapperList:[StreamWrapper] = []
    
    private let remoteLayer = UIView(frame: windowFrame())
    private let localLayer = UIView(frame: CGRect(x: 20, y: windowHeight()-200, width: 200, height: 200))
    private var roomKey:String!
    private let userId = String.getRandomStringWithLength(length: 8)
    
    deinit {
        print("ViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRoom()
        setupWamp()
        setupStream()
        
        Wamp.sharedInstance.connect()
        
        view.addSubview(localLayer)
        view.addSubview(remoteLayer)
        
        localLayer.backgroundColor = UIColor.blue
        
        localLayer.addSubview(WebRTC.localView)
    }
    
    private func setupStream(){
        WebRTC.setup()
    }
    
    private func setupRoom(){
        let roomKey:String? = "-Kr-JqhdoZ1YtdeO0-9r"
        
        if let roomKey = roomKey{
            self.roomKey = roomKey
            return
        }
        
        let ref = Database.database().reference().child("rooms")
        let roomRef = ref.childByAutoId()
        self.roomKey = roomRef.key
        
        print("roomKey:\(roomRef.key)")
    }
    
    private func setupWamp(){
        
        let wamp = Wamp.sharedInstance
        Wamp.sharedInstance.setup(roomKey: roomKey, userId: userId
        , callbacks: (
            onOpen:{() -> Void in
                print("onOpen")
                
                let topic = wamp.endpointCallme()
                wamp.session.publish(topic, options: [:], args: [self.userId], kwargs: [:])
            }
            , onReceiveOffer:{(targetId:String, sdp:NSDictionary) -> Void in
                print("onReceiveOffer")
                let connection = self.createConnection(targetId: targetId)
                connection.publishAnswer(offerSdp: sdp)
            }
            , onReceiveAnswer:{(targetId:String, sdp:NSDictionary) -> Void in
                print("onReceiveAnswer")
                guard let connection = self.findConnection(targetId: targetId) else{
                    return
                }
                connection.receiveAnswer(sdp: sdp)
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
                guard let streamIndex = self.streamWrapperList.index(where: { (row) -> Bool in
                    return row.targetId == targetId
                }) else{
                    return;
                }
                
                let streamWrapper = self.streamWrapperList.remove(at: streamIndex)
                streamWrapper.view.removeFromSuperview()
            }
       ))
    }
    
    private func createConnection(targetId:String)->Connection{
        let connection = Connection(myId: userId, targetId: targetId) { (streamWrapper) in
            print("onAeedStream")
            DispatchQueue.main.async {
                self.remoteLayer.addSubview(streamWrapper.view)
                self.streamWrapperList.append(streamWrapper)
                
                self.calcRemoteViewPosition()
            }
            
        }
        connectionList.append(connection)
        return connection
    }
    
    private func findConnection(targetId:String)->Connection?{
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
        
        for i in 0..<streamWrapperList.count{
            let view = streamWrapperList[i].view
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

