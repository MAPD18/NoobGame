//
//  GameScene.swift
//  NoobGame
//
//  Created by Rodrigo Silva on 2019-01-27.
//  Copyright © 2019 NoobJs. All rights reserved.
//

import SpriteKit
import GameplayKit

var gameScore = 0

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameScoreComputed : Int {
        get {
            return gameScore
        }
        set {
            gameScore = newValue
            scoreLabel.text = "Score: \(newValue)"
        }
    }
    let scoreLabel = SKLabelNode(fontNamed: "AlbaSuper")
    var lives = 3
    var livesComputed : Int {
        get {
            return lives
        }
        set {
            self.lives = newValue
            livesLabel.text = "Lives: \(newValue)"
        }
    }
    let livesLabel = SKLabelNode(fontNamed: "AlbaSuper")
    var levelNumber = 0
    var levelDurationByLevel : Dictionary<Int, TimeInterval> = [
        0 : 1.2,
        1 : 1,
        2 : 0.8,
        3 : 0.6,
        4 : 0.4
    ]
    
    let player = SKSpriteNode(imageNamed: "playerShip")
    let bulletSound = SKAction.playSoundFileNamed("bulletSoundEffect.wav", waitForCompletion: false)
    let enemyExposionSound = SKAction.playSoundFileNamed("shortExplosion.wav", waitForCompletion: false)
    let playerExplosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
    let gameArea: CGRect
    let tapToStartLabel = SKLabelNode(fontNamed: "AlbaSuper")
    
    var lastUpdateTime: TimeInterval = 0
    var deltaFrameTime: TimeInterval = 0
    let amountToMovePerSecond: CGFloat = 600.0
    
    enum gameState {
        case startScreen
        case duringGameplay
        case resultScreen
    }
    
    var currentGameState = gameState.startScreen
    
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
        
        gameScore = 0
        self.physicsWorld.contactDelegate = self
        
        for i in 0...1 {
            
            let background = SKSpriteNode(imageNamed: "background")
            background.size = self.size
            background.anchorPoint = CGPoint(x: 0.5, y: 0)
            background.position = CGPoint(x: self.size.width/2, y: self.size.height * CGFloat(i))
            background.zPosition = 0
            background.name = "Background"
            self.addChild(background)
            
        }
        
        player.setScale(1)
        player.position = CGPoint(x: self.size.width * 0.5, y: 0 - player.size.height)
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
        scoreLabel.position = CGPoint(x: self.size.width * 0.15, y: self.size.height + scoreLabel.frame.size.height)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        livesLabel.text = "Lives: 3"
        livesLabel.fontSize = 70
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        livesLabel.position = CGPoint(x: self.size.width * 0.85, y: self.size.height + livesLabel.frame.size.height)
        livesLabel.zPosition = 100
        self.addChild(livesLabel)
        
        let moveToScreenAction = SKAction.moveTo(y: self.size.height * 0.9, duration: 0.3)
        scoreLabel.run(moveToScreenAction)
        livesLabel.run(moveToScreenAction)
        
        tapToStartLabel.text = "Tap to Start"
        tapToStartLabel.fontSize = 100
        tapToStartLabel.fontColor = SKColor.white
        tapToStartLabel.zPosition = 1
        tapToStartLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        tapToStartLabel.alpha = 0
        self.addChild(tapToStartLabel)
        
        let fadeInAction = SKAction.fadeIn(withDuration: 0.3)
        tapToStartLabel.run(fadeInAction)
        
    }
    
    // Runs once per game frame
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        else{
            deltaFrameTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
        }
        
        let amountToMoveBackground = amountToMovePerSecond * CGFloat(deltaFrameTime)
        
        self.enumerateChildNodes(withName: "Background", using: {
            background, stop in
            
            if self.currentGameState == gameState.duringGameplay {
                background.position.y -= amountToMoveBackground
            }
            
            if background.position.y < -self.size.height {
                background.position.y += self.size.height * 2
            }
        })
        
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
            
            gameOver()
            
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
        
        if gameScore == 5 || gameScore == 10 || gameScore == 15 {
            startNewLevel()
        }
    }
    
    func startGame() {
        
        currentGameState = gameState.duringGameplay
        
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
        let deleteAction = SKAction.removeFromParent()
        let deleteSequence = SKAction.sequence([fadeOutAction, deleteAction])
        tapToStartLabel.run(deleteSequence)
        
        let moveShipToScreenAction = SKAction.moveTo(y: self.size.height * 0.2, duration: 0.5)
        let startLevelAction = SKAction.run(startNewLevel)
        let startGameSequence = SKAction.sequence([moveShipToScreenAction, startLevelAction])
        player.run(startGameSequence)
        
    }
    
    func updateLives() {
        lives = lives - 1
        livesLabel.text = "Lives: \(lives)"
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        livesLabel.run(scaleSequence)
        
        if lives == 0 {
            gameOver()
        }
        
    }
    
    func gameOver() {
        
        currentGameState = gameState.resultScreen
        
        self.removeAllActions()
        
        self.enumerateChildNodes(withName: "Bullet", using: {
            bullet, stop in
            bullet.removeAllActions()
        })
        
        self.enumerateChildNodes(withName: "Enemy", using: {
            enemy, stop in
            enemy.removeAllActions()
        })
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene = SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChangeScene, changeSceneAction])
        self.run(changeSceneSequence)
        
    }
    
    func changeScene() {
        
        let newScene = GameOverScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        let transitionEffect = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(newScene, transition: transitionEffect)
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
        levelNumber += 1
        
        if self.action(forKey: "spawningEnemies") != nil {
            self.removeAction(forKey: "spawningEnemies")
        }
        
        let newLevelLabel = SKAction.run(showNewLevelLabel)
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDurationByLevel[levelNumber, default: 4])
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        
        let mainSequence = SKAction.sequence([newLevelLabel, spawnForever])
        self.run(mainSequence, withKey: "spawningEnemies")
        
        showNewLevelLabel()
    }
    
    func showNewLevelLabel() {
        let newLevelLabel = SKLabelNode(fontNamed: "AlbaSuper")
        newLevelLabel.text = "Starting Level \(self.levelNumber)"
        newLevelLabel.fontSize = 120
        newLevelLabel.fontColor = SKColor.white
        newLevelLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        newLevelLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height*0.5)
        newLevelLabel.zPosition = 100
        newLevelLabel.setScale(0)
        self.addChild(newLevelLabel)
        
        let fadeIn = SKAction.scale(to: 1, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let removeLabel = SKAction.removeFromParent()
        let newLevelSequence = SKAction.sequence([fadeIn, fadeOut, removeLabel])
        newLevelLabel.run(newLevelSequence)
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.name = "Bullet"
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
        enemy.name = "Enemy"
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
        let loseALifeAction = SKAction.run(updateLives)
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, loseALifeAction])
        
        if currentGameState == gameState.duringGameplay {
            enemy.run(enemySequence)
        }
        
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy, dx)
        enemy.zRotation = amountToRotate
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentGameState == gameState.startScreen {
            startGame()
        }
        
        else if currentGameState == gameState.duringGameplay{
            fireBullet()
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let ammountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            if currentGameState == gameState.duringGameplay {
                player.position.x += ammountDragged
            }
            
            if player.position.x > (gameArea.maxX - player.size.width * 0.5 ) {
                player.position.x = gameArea.maxX - player.size.width * 0.5
            }
            
            if player.position.x < (gameArea.minX + player.size.width * 0.5 ) {
                player.position.x = gameArea.minX + player.size.width * 0.5
            }
        }
    }
}
