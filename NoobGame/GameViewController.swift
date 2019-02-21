//
//  GameViewController.swift
//  NoobGame
//
//  Created by Rodrigo Silva on 2019-01-27.
//  Copyright © 2019 NoobJs. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {
    
    var backgroundAudio = AVAudioPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filePath = Bundle.main.path(forResource: "bgMusic", ofType: "mp3")
        let audioNSURL = NSURL(fileURLWithPath: filePath!)
        
        do {
            backgroundAudio = try AVAudioPlayer(contentsOf: audioNSURL as URL)
        }
        catch {
            return print("Audio Not Found")
        }
        
        backgroundAudio.numberOfLoops = -1
        backgroundAudio.play()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            let scene  = MainMenuScene(size: CGSize(width: 1536, height: 2048))
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
