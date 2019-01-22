import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    var gameScene: GameScene!
    var pauseViewController: PauseViewController!
    var gameOverViewController: GameOverViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pauseViewController = (storyboard?.instantiateViewController(withIdentifier: "PauseViewController") as!  PauseViewController)
        gameOverViewController = storyboard?.instantiateViewController(withIdentifier: "gameOverViewController") as? GameOverViewController
        pauseViewController.delegate = self
        gameOverViewController.delegate = self
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                gameScene = scene as? GameScene
                gameScene.gameViewControllerBridge = self
                gameScene.gameOverViewControllerBridge = gameOverViewController
                
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
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
    
    func showPauseScreen(_ viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        
        viewController.view.alpha = 0
        UIView.animate(withDuration: 0.5) {
            viewController.view.alpha = 1
        }
    }
    
    func hidePauseScreen(viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        viewController.view.alpha = 1
        UIView.animate(withDuration: 0.5, animations: {
            viewController.view.alpha = 0
        }) { (completed) in
            viewController.view.removeFromSuperview()
        }
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        gameScene.pauseTheGame()
        showPauseScreen(pauseViewController)
    }
    
}

extension GameViewController: PauseVCDelegate {
    func pauseViewControllerMusicButton(_ viewController: PauseViewController) {
        gameScene.isMusicOn = !gameScene.isMusicOn
    }
    
    func pauseViewControllerPlayButton(_ viewController: PauseViewController) {
        hidePauseScreen(viewController: pauseViewController)
        gameScene.unpauseTheGame()
    }
}

extension GameViewController: GameOverDelegate {
    func gameOverVCReplyButtonPressed(_ viewController: GameOverViewController) {
        hidePauseScreen(viewController: gameOverViewController)
        gameScene.restartGame()
    }
}
