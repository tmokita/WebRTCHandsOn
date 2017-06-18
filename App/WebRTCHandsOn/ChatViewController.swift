//
//  ChatViewController.swift
//  WebRTCHandsOn
//
//  Created by TOMOHIKO OKITA on 2017/06/17.
//  Copyright © 2017年 TOMOHIKO OKITA. All rights reserved.
//

import UIKit
import WebRTC
import Starscream

class ChatViewController: UIViewController, WebSocketDelegate {

    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var cameraPreview: RTCCameraPreviewView!
    
    var webSocket: WebSocket! = nil
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var audioSource: RTCAudioSource?
    var videoSource: RTCAVFoundationVideoSource?
    
    deinit {
        // 解放順に注意が必要
        audioSource = nil
        videoSource = nil
        peerConnectionFactory = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        peerConnectionFactory = RTCPeerConnectionFactory()
        
        startVideo()
        
        // WebSocket Initialize
        let url  = URL(string: "wss://conf.space/WebRTCHandsOnSig/tmokita")!
        webSocket = WebSocket(url: url)
        webSocket.delegate = self
        webSocket.connect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onClose(_ sender: Any) {
        webSocket.disconnect()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onConnect(_ sender: Any) {
    }
    
    @IBAction func onHangUp(_ sender: Any) {
    }
    
    // MARK: - LOG
    func LOG(_ body: String = "",
             function: String = #function,
             line: Int = #line)
    {
        print("[\(function) : \(line)] \(body)")
    }

    // MARK: - WebSocketDelegate
    func websocketDidConnect(socket: WebSocket) {
        LOG()
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        LOG("error : \(String(describing: error?.localizedDescription))")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        LOG("message : \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        LOG("data.count : \(data.count)")
    }
    
    func startVideo() {
        // この中身を書いていきます
        
        // 音声ソースの生成
        let audioSourceConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        audioSource = peerConnectionFactory.audioSource(with: audioSourceConstraints)
        
        // 映像ソースの設定
        let videoSourceConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        videoSource = peerConnectionFactory.avFoundationVideoSource(with: videoSourceConstraints)
        
        // 映像ソースをプレビューに設定
        cameraPreview.captureSession = videoSource?.captureSession
        
    }
}
