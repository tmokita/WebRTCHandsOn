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

class ChatViewController: UIViewController, WebSocketDelegate, RTCPeerConnectionDelegate {

    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var cameraPreview: RTCCameraPreviewView!
    
    var webSocket: WebSocket! = nil
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var audioSource: RTCAudioSource!
    var videoSource: RTCAVFoundationVideoSource!
    var peerConnection: RTCPeerConnection! = nil
    
    deinit {
        if peerConnection != nil {
            hangUp()
        }

        // 解放順に注意が必要
        // 順番が違っているとぬるぽで落ちる
        // チャット画面が終了したか落ちたかわかりづらいので注意
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
        if peerConnection == nil {
            peerConnection = prepareNewConnection()
        }
    }
    
    @IBAction func onHangUp(_ sender: Any) {
        hangUp()
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
    
    
    // MARK: - RTCPeerConnectionDelegate
    func prepareNewConnection() -> RTCPeerConnection {
        
        var connetion: RTCPeerConnection! = nil
        
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer.init(urlStrings:["stun:stun.l.google.com:19302"])]
        // PeerConecctionの設定(今回はなし)
        let peerConnectionConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        // PeerConnectionの初期化
        connetion = peerConnectionFactory.peerConnection(with: configuration, constraints: peerConnectionConstraints, delegate: self)
        
        // 音声トラックの作成
        let localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "ARDAMSa0")
        // PeerConnectionからAudioのSenderを作成
        let audioSender = connetion.sender(withKind: kRTCMediaStreamTrackKindAudio, streamId: "ARDAMS")
        // Senderにトラックを設定
        audioSender.track = localAudioTrack
        
        // 映像トラックの作成
        let localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "ARDAMSv0")
        // PeerConnectionからVideoのSenderを作成
        let videoSender = connetion.sender(withKind: kRTCMediaStreamTrackKindVideo, streamId: "ARDAMS")
        // Senderにトラックを設定
        videoSender.track = localVideoTrack
        
        return connetion
    }
    
    /** Called when the SignalingState changed. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
    }
    
    /** Called when media is received on a new stream from remote peer. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
    }
    
    /** Called when a remote peer closes a stream. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
    }
    
    /** Called when negotiation is needed, for example ICE has restarted. */
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
    
    }
    
    /** Called any time the IceConnectionState changes. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        // PeerConnectionの接続状況が変化した際に呼ばれます
        var state = ""
        switch (newState) {
        case RTCIceConnectionState.checking:
            state = "checking"
        case RTCIceConnectionState.completed:
            state = "completed"
        case RTCIceConnectionState.connected:
            state = "connected"
        case RTCIceConnectionState.closed:
            state = "closed"
            hangUp()
        case RTCIceConnectionState.failed:
            state = "failed"
            hangUp()
        case RTCIceConnectionState.disconnected:
            state = "disconnected"
        default:
            break
        }
        LOG("ICE connection Status has changed to \(state)")
    }
    
    /** Called any time the IceGatheringState changes. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
    
    }
    
    /** New ice candidate has been found. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
    
    }
    
    /** Called when a group of local Ice candidates have been removed. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
    
    }
    
    /** New data channel has been opened. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
    }
    
    //
    func hangUp() {
        if peerConnection != nil {
            if peerConnection.iceConnectionState != RTCIceConnectionState.closed {
                peerConnection.close()
            }
            peerConnection = nil
            LOG("peerConnection is closed.")
        }
    }
}
