//
//  GameScene.swift
//  NoobGame
//
//  Created by Rodrigo Silva on 2019-01-27.
//  Copyright © 2019 NoobJs. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameScore = 0
    var gameScoreComputed : Int {
        get {
            return gameScore
        }
        set {
            self.gameScore = newValue
            scoreLabel.text = "Score: \(newValue)"
        }
    }
    let scoreLabel = SKLabelNode(fontNamed: "AlbaSuper")
    
    
    let player = SKSpriteNode(imageNamed: "playerShip")
    let bulletSound = SKAction.playSoundFileNamed("bulletSoundEffect.wav", waitForCompletion: false)
    let enemyExposionSound = SKAction.playSoundFileNamed("shortExplosion.wav", waitForCompletion: false)
    let playerExplosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
    let gameArea: CGRect
    
    struct PhysicsCategories {
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1 //1
        static let Bullet : UInt32 = 0b10 //2
        static let Enemy : UInt32 = 0b100 //4
    }
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        let background = SKSpriteNode(imageNamed: "background")
        background.size = self.size
        background.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        background.zPosition = 0
        self.addChild(background)
        
        player.setScale(1)
        player.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.2)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategories.Player
        player.physicsBody?.collisionBitMask = PhysicsCategories.None
        player.physicsBody?.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(player)
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width * 0.15, y: self.size.height*0.9)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        startNewLevel()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        switch categoryOf(contact: contact){
        case .enemyPlayer:
            if let nodeA = contact.bodyA.node {
                spawnExplosionTo(position: nodeA.position, category: contact.bodyA.categoryBitMask)
            }
            if let nodeB = contact.bodyB.node {
                spawnExplosionTo(position: nodeB.position, category: contact.bodyB.categoryBitMask)
            }
            
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            break
        case .enemyBullet:
            let bulletBody = contact.bodyA.categoryBitMask == PhysicsCategories.Bullet ? contact.bodyA : contact.bodyB
            let enemyBody = contact.bodyB.categoryBitMask == PhysicsCategories.Enemy ? contact.bodyB : contact.bodyA
            if let enemyBodyNode = enemyBody.node {
                spawnExplosionTo(position: enemyBodyNode.position, category: enemyBody.categoryBitMask)
            }
            bulletBody.node?.removeFromParent()
            enemyBody.node?.removeFromParent()
            
            addScore()
            break
        default:
            break
        }
    }
    
    func addScore() {
        gameScoreComputed += 1
    }
    
    enum ContactCategory {
        case enemyBullet, enemyPlayer, none
    }
    
    func categoryOf(contact: SKPhysicsContact) -> ContactCategory {
        if (contact.bodyA.categoryBitMask == PhysicsCategories.Player && contact.bodyB.categoryBitMask == PhysicsCategories.Enemy) || (contact.bodyA.categoryBitMask == PhysicsCategories.Enemy && contact.bodyB.categoryBitMask == PhysicsCategories.Player) {
            return .enemyPlayer
        } else if (contact.bodyA.categoryBitMask == PhysicsCategories.Bullet && contact.bodyB.categoryBitMask == PhysicsCategories.Enemy && (contact.bodyB.node?.position.y)! < self.size.height) || (contact.bodyA.categoryBitMask == PhysicsCategories.Enemy && contact.bodyB.categoryBitMask == PhysicsCategories.Bullet && (contact.bodyA.node?.position.y)! < self.size.height) {
            return .enemyBullet
        }
        return .none;
    }
    
    func spawnExplosionTo(position: CGPoint, category: UInt32) {
        let explosion = SKSpriteNode.init(imageNamed: "explosion")
        explosion.position = position
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        let explosionSound = category == PhysicsCategories.Player ? playerExplosionSound : enemyExposionSound
        let explosionSequence = SKAction.sequence([explosionSound, scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
    }
    
    func startNewLevel() {
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: 1)
        let spawnSequence = SKAction.sequence([spawn, waitToSpawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever)
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.setScale(1)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody?.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody?.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet, deleteBullet])
        bullet.run(bulletSequence)
    }
    
    func spawnEnemy() {
        
        let randomXStart = CGFloat(Float.random(in: Float(gameArea.minX)..<Float(gameArea.maxX)))
        let randomXEnd = CGFloat(Float.random(in: Float(gameArea.minX)..<Float(gameArea.maxX)))
        
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "enemyShip")
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody?.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody?.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.5)
        let deleteEnemy = SKAction.removeFromParent()
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy])
        enemy.run(enemySequence)
        
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy, dx)
        enemy.zRotation = amountToRotate
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let ammountDragged = pointOfTouch.x - previousPointOfTouch.x
            player.position.x += ammountDragged
            
            if player.position.x > (gameArea.maxX - player.size.width * 0.5 ) {
                player.position.x = gameArea.maxX - player.size.width * 0.5
            }
            
            if player.position.x < (gameArea.minX + player.size.width * 0.5 ) {
                player.position.x = gameArea.minX + player.size.width * 0.5
            }
        }
    }
}
