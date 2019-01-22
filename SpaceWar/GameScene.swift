import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameViewControllerBridge: GameViewController!
    var gameOverViewControllerBridge: GameOverViewController!
    
    let spaceShipCategory: UInt32 = 0x1 << 0
    let asteroidCategory: UInt32 = 0x1 << 1
    var spaceShip: SKSpriteNode!
    var score = 0
    var scoreLabel: SKLabelNode!
    var spaceBackground: SKSpriteNode!
    var asteroidLayer: SKNode!
    var starsLayer: SKNode!
    var spaceShipLayer: SKNode!
    var musicPlayer: AVAudioPlayer!
    var isMusicOn = true
    
    func restartGame() {
        spaceShipLayer.position = CGPoint(x: 0, y: 0)
        asteroidLayer.removeAllChildren()
        unpauseTheGame()
        score = 0
        scoreLabel.text = "Score: \(score)"
        playMusic()
    }
    
    func musicOnOrOff() {
        if isMusicOn {
            musicPlayer.play()
        } else {
            musicPlayer.stop()
            musicPlayer.currentTime = TimeInterval(0)
        }
    }
    
    var gameIsPause: Bool = false
    func pauseTheGame() {
        gameIsPause = true
        self.asteroidLayer.isPaused = true
        physicsWorld.speed = 0
        starsLayer.isPaused = true
        musicPlayer.stop()
        musicPlayer.currentTime = TimeInterval(0)
    }
    func unpauseTheGame() {
         gameIsPause = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
        starsLayer.isPaused = false
        musicOnOrOff()
    }
    func resetTheGame() {
        score = 0
        scoreLabel.text = "Score: \(score)"
        gameIsPause = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
        starsLayer.isPaused = false
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -0.8)
        
        scene?.size = UIScreen.main.bounds.size
        
        spaceBackground = SKSpriteNode(imageNamed: "space")
        spaceBackground.size = CGSize(width: UIScreen.main.bounds.width + 50, height: UIScreen.main.bounds.height + 50)
        spaceBackground.zPosition = 0
        addChild(spaceBackground)
        
        if let starsEmmiter = SKEmitterNode(fileNamed: "Stars.sks") {
            starsEmmiter.zPosition = 0
            starsEmmiter.position = CGPoint(x: frame.midX, y: frame.height / 2)
            starsEmmiter.particlePositionRange.dx = frame.width
            starsEmmiter.advanceSimulationTime(10)
            starsLayer = SKNode()
            starsLayer.zPosition = 0
            addChild(starsLayer)
            starsLayer.addChild(starsEmmiter)
        }
        
        spaceShip = SKSpriteNode(imageNamed: "cor")
        spaceShip.xScale = 0.4
        spaceShip.yScale = 0.4
        spaceShip.physicsBody = SKPhysicsBody(texture: spaceShip.texture!, size: spaceShip.size)
        spaceShip.physicsBody?.isDynamic = false
        spaceShip.physicsBody?.categoryBitMask = spaceShipCategory
        spaceShip.physicsBody?.collisionBitMask = asteroidCategory
        spaceShip.physicsBody?.contactTestBitMask = asteroidCategory
        
        let colorAction1 = SKAction.colorize(with: .yellow, colorBlendFactor: 1, duration: 1)
        let colorAction2 = SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 1)
        let colorSequence = SKAction.sequence([colorAction1, colorAction2])
        let colorActionRepeat = SKAction.repeatForever(colorSequence)
        spaceShip.run(colorActionRepeat)
        
        spaceShipLayer = SKNode()
        spaceShipLayer.addChild(spaceShip)
        spaceShipLayer.zPosition = 3
        spaceShip.zPosition = 1
        spaceShipLayer.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(spaceShipLayer)
        
        if let fireEmmiter = SKEmitterNode(fileNamed: "Fire.sks") {
            fireEmmiter.zPosition = 0
            fireEmmiter.position.y = -30
            fireEmmiter.targetNode = self
            spaceShipLayer.addChild(fireEmmiter)
        }
        
        asteroidLayer = SKNode()
        asteroidLayer.zPosition = 2
        addChild(asteroidLayer)
        
        let asteroidCreate = SKAction.run {
            let asteroid = self.createAsteroid()
            asteroid.zPosition = 2
            self.asteroidLayer.addChild(asteroid)
        }
        let asteroidPerSecond: Double = 1
        let asteroidCreationDelay = SKAction.wait(forDuration: 1.0 / asteroidPerSecond, withRange: 0.5)
        let asteroidSequenceAction = SKAction.sequence([asteroidCreate, asteroidCreationDelay])
        let asteroidRunAction = SKAction.repeatForever(asteroidSequenceAction)
        self.asteroidLayer.run(asteroidRunAction)
        
        scoreLabel = SKLabelNode(text: "Score: \(score)")
        let scoreLabelXPosition = frame.minX + scoreLabel.frame.maxX + 15
        let screenHeight = UIScreen.main.nativeBounds.height
        let isIphoneX = screenHeight == 2436 || screenHeight == 2688 || screenHeight == 1792
        let iphoneTopInset = isIphoneX ? 44 : 0
        let scoreLabelYPosition = frame.maxY - scoreLabel.frame.height - 15 - CGFloat(iphoneTopInset)
        scoreLabel.position = CGPoint(x: scoreLabelXPosition,y: scoreLabelYPosition)
        scoreLabel.fontSize = 30
        scoreLabel.zPosition = 3
        addChild(scoreLabel)
        
        playMusic()
        
    }
    
    func playMusic() {
        let randomInt = Int.random(in: 1...2)
        let musicPath = Bundle.main.url(forResource: "background"+String(randomInt), withExtension: "mp3")!
        musicPlayer = try! AVAudioPlayer(contentsOf: musicPath, fileTypeHint: nil)
        musicOnOrOff()
        musicPlayer.numberOfLoops = -1
        musicPlayer.volume = 0.2
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameIsPause {
            if let touch = touches.first {
                let touchLocation = touch.location(in: self)
                
                let distance = distanceCalc(a: spaceShip.position, b: touchLocation)
                let speed: CGFloat = 250
                let time = timeToTravelDistance(distance: distance, speed: speed)
                let moveAction = SKAction.move(to: touchLocation, duration: time)
                moveAction.timingMode = SKActionTimingMode.easeInEaseOut
                
                let angleShipRotate: CGFloat
                if touchLocation.x < self.spaceShipLayer.position.x {
                    angleShipRotate = 0.5
                } else {
                    angleShipRotate = -0.5
                }
                let rotateAction = SKAction.rotate(byAngle: angleShipRotate, duration: time/3)
                let rotateWait = SKAction.wait(forDuration: time/3)
                let rotateBackAction = SKAction.rotate(byAngle: -angleShipRotate, duration: time/3)
                let actionTouchSeguence = SKAction.sequence([rotateAction, rotateWait, rotateBackAction])
                let actionTouchGroup = SKAction.group([actionTouchSeguence, moveAction])
                spaceShipLayer.run(actionTouchGroup)
                
                let bgMoveAction = SKAction.move(to: CGPoint(x: -touchLocation.x / 50, y: -touchLocation.y / 50), duration: time)
                spaceBackground.run(bgMoveAction)
            }
        }
    }
    
    func distanceCalc(a: CGPoint, b: CGPoint) -> CGFloat {
        return sqrt((b.x - a.x)*(b.x - a.x) + (b.y - a.y)*(b.y - a.y))
    }
    
    func timeToTravelDistance(distance: CGFloat, speed: CGFloat) -> TimeInterval {
        let time = distance / speed
        return TimeInterval(time)
    }
    
    func createAsteroid() -> SKSpriteNode {
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        let randomScale = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 6)) / 10 + 1
        asteroid.xScale = randomScale
        asteroid.yScale = randomScale
        asteroid.position.x = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 16))
        asteroid.position.y = frame.size.height + asteroid.size.height
        asteroid.physicsBody = SKPhysicsBody(texture: asteroid.texture!, size: asteroid.size)
        asteroid.name = "asteroid"
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.collisionBitMask = spaceShipCategory | asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = spaceShipCategory
        let asteroidSpeedX: CGFloat = 100
        asteroid.physicsBody?.angularVelocity = CGFloat(drand48() * 2 - 1) * 3
        asteroid.physicsBody?.velocity.dx = CGFloat(drand48() * 2 - 1) * asteroidSpeedX
        return asteroid
    }
    
    override func didSimulatePhysics() {
        asteroidLayer.enumerateChildNodes(withName: "asteroid") { (asteroid, stop) in
            let heightScreen = UIScreen.main.bounds.height
            if asteroid.position.y < -heightScreen {
                asteroid.removeFromParent()
                self.score += 1
                self.scoreLabel.text = "Score: \(self.score)"                
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == spaceShipCategory && contact.bodyB.categoryBitMask == asteroidCategory || contact.bodyB.categoryBitMask == spaceShipCategory && contact.bodyA.categoryBitMask == asteroidCategory {

            pauseTheGame()

            gameViewControllerBridge.addChild(gameOverViewControllerBridge)
            gameViewControllerBridge.view.addSubview(gameOverViewControllerBridge.view)
            gameOverViewControllerBridge.view.frame = gameViewControllerBridge.view.bounds

            gameOverViewControllerBridge.scoreLabel.text = "\(self.score)"
            
            let maxScore = UserDefaults.standard.integer(forKey: "record")
            if maxScore < score {
                UserDefaults.standard.set(score, forKey: "record")
            }
            gameOverViewControllerBridge.maxScoreLabel.text = "\(maxScore)"
            
            gameOverViewControllerBridge.view.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self.gameOverViewControllerBridge.view.alpha = 1
            }
        }
        
        let hitSoundAction = SKAction.playSoundFileNamed("hit.mp3", waitForCompletion: true)
        run(hitSoundAction)
        let musicPath = Bundle.main.url(forResource: "sad", withExtension: "mp3")!
        musicPlayer = try! AVAudioPlayer(contentsOf: musicPath, fileTypeHint: nil)
        musicPlayer.play()
        musicPlayer.numberOfLoops = 0
        musicPlayer.volume = 0.2
    }

}
