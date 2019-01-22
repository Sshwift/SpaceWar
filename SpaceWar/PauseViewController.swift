import UIKit

protocol PauseVCDelegate {
    func pauseViewControllerPlayButton(_ viewController: PauseViewController)
    func pauseViewControllerMusicButton(_ viewController: PauseViewController)
}

class PauseViewController: UIViewController {

    var delegate: PauseVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func playButtonPress(_ sender: UIButton) {
        delegate.pauseViewControllerPlayButton(self)
    }
    
    @IBAction func musicSwitchChange(_ sender: UISwitch) {
        delegate.pauseViewControllerMusicButton(self)
    }
    
}
