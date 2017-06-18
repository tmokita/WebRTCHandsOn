//
//  ChatViewController.swift
//  WebRTCHandsOn
//
//  Created by TOMOHIKO OKITA on 2017/06/17.
//  Copyright © 2017年 TOMOHIKO OKITA. All rights reserved.
//

import UIKit
import WebRTC

class ChatViewController: UIViewController {

    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var cameraPreview: RTCCameraPreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onConnect(_ sender: Any) {
    }
    
    @IBAction func onHangUp(_ sender: Any) {
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
