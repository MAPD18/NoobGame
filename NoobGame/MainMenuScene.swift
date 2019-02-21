//
//  MainMenuScene.swift
//  NoobGame
//
//  Created by Thayllan Anacleto on 2019-02-21.
//  Copyright © 2019 NoobJs. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        background.zPosition = 0
        self.addChild(background)
        
        let gameBy = SKLabelNode(fontNamed: "AlbaSuper")
        gameBy.text = "NoobGame's"
        gameBy.fontSize = 50
        gameBy.fontColor = SKColor.white
        gameBy.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.78)
        gameBy.zPosition = 1
        self.addChild(gameBy)
        
        let gameName1 = SKLabelNode(fontNamed: "AlbaSuper")
        gameName1.text = "Space"
        gameName1.fontSize = 200
        gameName1.fontColor = SKColor.white
        gameName1.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.7)
        gameName1.zPosition = 1
        self.addChild(gameName1)
        
        let gameName2 = SKLabelNode(fontNamed: "AlbaSuper")
        gameName2.text = "Intruders"
        gameName2.fontSize = 200
        gameName2.fontColor = SKColor.white
        gameName2.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.625)
        gameName2.zPosition = 1
        self.addChild(gameName2)
        
        let playGame = SKLabelNode(fontNamed: "AlbaSuper")
        playGame.text = "PLAY"
        playGame.fontSize = 150
        playGame.fontColor = SKColor.white
        playGame.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.4)
        playGame.zPosition = 1
        playGame.name = "play"
        self.addChild(playGame)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            
            let pointOfTouch = touch.location(in: self)
            let tappedNode = atPoint(pointOfTouch)
            
            if tappedNode.name == "play" {
                
                let newScene = GameScene(size: self.size)
                newScene.scaleMode = self.scaleMode
                let transitionEffect = SKTransition.fade(withDuration: 0.5)
                self.view!.presentScene(newScene, transition: transitionEffect)
                
            }
            
        }
        
    }
    
}
