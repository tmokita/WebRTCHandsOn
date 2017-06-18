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
import SwiftyJSON

class ChatViewController: UIViewController, WebSocketDelegate, RTCPeerConnectionDelegate {

    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var cameraPreview: RTCCameraPreviewView!
    
    var websocket: WebSocket! = nil
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var audioSource: RTCAudioSource!
    var videoSource: RTCAVFoundationVideoSource!
    var peerConnection: RTCPeerConnection! = nil
    var remoteVideoTrack: RTCVideoTrack?
    
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
        websocket = WebSocket(url: url)
        websocket.delegate = self
        websocket.connect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onClose(_ sender: Any) {
        websocket.disconnect()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onConnect(_ sender: Any) {
        // Connectボタンを押した時
        if peerConnection == nil {
            LOG("make Offer")
            makeOffer()
        } else {
            LOG("peer already exist.")
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
    
    // setAnswer の呼び出し
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        
        LOG("message: \(text)")
        
        // 受け取ったメッセージをJSONとしてパース
        let jsonMessage = JSON.parse(text)
        let type = jsonMessage["type"].stringValue
        
        switch (type) {
        case "answer":
            // answerを受け取った時の処理
            LOG("Received answer ...")
            let answer = RTCSessionDescription(type: RTCSessionDescription.type(for: type), sdp: jsonMessage["sdp"].stringValue)
            setAnswer(answer)
            
        case "candidate":
            LOG("Received ICE candidate ...")
            let candidate = RTCIceCandidate(
                sdp: jsonMessage["ice"]["candidate"].stringValue,
                sdpMLineIndex:
                jsonMessage["ice"]["sdpMLineIndex"].int32Value,
                sdpMid: jsonMessage["ice"]["sdpMid"].stringValue)
            addIceCandidate(candidate)
            
        case "offer":
            // offerを受け取った時の処理
            LOG("Received offer ...")
            let offer = RTCSessionDescription(
                type: RTCSessionDescription.type(for: type),
                sdp: jsonMessage["sdp"].stringValue)
            setOffer(offer)
            
        case "close":
            LOG("peer is closed ...")
            hangUp()
            
        default:
            return
        }
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
        
        // 映像/音声が追加された際に呼ばれます
        LOG("-- peer.onaddstream()")
        
        DispatchQueue.main.async(execute: { [unowned self] () -> Void in
            // mainスレッドで実行
            if (stream.videoTracks.count > 0) {
                // ビデオのトラックを取り出して
                self.remoteVideoTrack = stream.videoTracks[0]
                // remoteVideoViewに紐づける
                self.remoteVideoTrack?.add(self.remoteVideoView)
            }
        })
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
    
        // Candidate(自分への接続先候補情報)が生成された際に呼ばれます
        if candidate.sdpMid != nil {
            sendIceCandidate(candidate)
        } else {
            LOG("empty ice event")
        }
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
                
                let jsonClose: JSON = [
                    "type": "close"
                ]
                LOG("sending close message")
                websocket.write(string: jsonClose.rawString()!)
            }
            if remoteVideoTrack != nil {
                remoteVideoTrack?.remove(remoteVideoView)
            }
            remoteVideoTrack = nil
            peerConnection = nil
            LOG("peerConnection is closed.")
        }
    }
    
    // SDPの入っているRTCSessionDescription型のdescから必要な値を取り出してJSONに格納しwebsocket.writeで相手に送信します。
    func sendSDP(_ desc: RTCSessionDescription) {
        LOG("---sending sdp ---")
        let jsonSdp: JSON = [
            "sdp": desc.sdp, // SDP本体
            "type": RTCSessionDescription.string(for: desc.type) // offer か answer か
        ]
        
        // JSONを生成
        let message = jsonSdp.rawString()!
        
        LOG("sending SDP=" + message)
        
        // 相手に送信
        websocket.write(string: message)
    }
    
    // PeerConnectionを作ってからofferを相手に送るところまで
    func makeOffer() {
        // PeerConnectionを生成
        peerConnection = prepareNewConnection()
        // Offerの設定 今回は映像も音声も受け取る
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ], optionalConstraints: nil)
        let offerCompletion = { (offer: RTCSessionDescription?, error: Error?) in
            
            // Offerの生成が完了した際の処理
            if error != nil { return }
            self.LOG("createOffer() succsess")
            
            let setLocalDescCompletion = {(error: Error?) in
                // setLocalDescCompletionが完了した際の処理
                if error != nil { return }
                self.LOG("setLocalDescription() succsess")
                // 相手に送る
                self.sendSDP(offer!)
            }
            
            // 生成したOfferを自分のSDPとして設定
            self.peerConnection.setLocalDescription(offer!, completionHandler: setLocalDescCompletion)
        }
        // Offerを生成
        self.peerConnection.offer(for: constraints, completionHandler: offerCompletion)
    }
    
    // Answerが帰ってくるので受け取る処理
    func setAnswer(_ answer: RTCSessionDescription) {
        if peerConnection == nil {
            LOG("peerConnection NOT exist!")
            return
        }
        
        // 受け取ったSDPを相手のSDPとして設定
        self.peerConnection.setRemoteDescription(answer,
                                                 completionHandler: { (error: Error?) in
                                                    if error == nil {
                                                        self.LOG("setRemoteDescription(answer) succsess")
                                                    } else {
                                                        self.LOG("setRemoteDescription(answer) ERROR: " + error.debugDescription)
                                                    }
        })
    }
    
    //
    func sendIceCandidate(_ candidate: RTCIceCandidate) {
        LOG("---sending ICE candidate ---")
        
        let jsonCandidate: JSON = [
            "type": "candidate",
            "ice": [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid!
            ]
        ]
        
        let message = jsonCandidate.rawString()!
        
        LOG("sending candidate=" + message)
        websocket.write(string: message)
    }
    
    //
    func addIceCandidate(_ candidate: RTCIceCandidate) {
        if peerConnection != nil {
            peerConnection.add(candidate)
        } else {
            LOG("PeerConnection not exist!")
        }
    }
    
    //
    func setOffer(_ offer: RTCSessionDescription) {
        if peerConnection != nil {
            LOG("peerConnection alreay exist!")
        }
        // PeerConnectionを生成する
        peerConnection = prepareNewConnection()
        self.peerConnection.setRemoteDescription(offer, completionHandler: {[unowned self] (error: Error?) in
            if error == nil {
                self.LOG("setRemoteDescription(offer) succsess")
                // setRemoteDescriptionが成功したらAnswerを作る
                self.makeAnswer()
            } else {
                self.LOG("setRemoteDescription(offer) ERROR: " + error.debugDescription)
            }
        })
    }

    //
    func makeAnswer() {
        LOG("sending Answer. Creating remote session description...")
        if peerConnection == nil {
            LOG("peerConnection NOT exist!")
            return
        }
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let answerCompletion = { (answer: RTCSessionDescription?, error: Error?) in
            if error != nil { return }
            self.LOG("createAnswer() succsess")
            let setLocalDescCompletion = {(error: Error?) in
                if error != nil { return }
                self.LOG("setLocalDescription() succsess")
                // 相手に送る
                self.sendSDP(answer!)
            }
            self.peerConnection.setLocalDescription(answer!, completionHandler: setLocalDescCompletion)
        }
        // Answerを生成
        self.peerConnection.answer(for: constraints, completionHandler: answerCompletion)
    }

}
