import UIKit
import Pagecall

struct EmojiMessage: Codable {
    let emoji: String
    let sender: String
}

class ViewController: UIViewController, PagecallDelegate {
    func pagecallDidClose(_ controller: Pagecall.PagecallWebViewController) {
        controller.dismiss(animated: true)
    }

    @IBOutlet weak var roomIdField: UITextField!

    @IBAction func enterTapped(_ sender: Any) {
        guard let roomId = roomIdField.text else { return }
        if roomId.isEmpty { return }

        let pagecallWebViewController = PagecallWebViewController()
        pagecallWebViewController.delegate = self
        _ = pagecallWebViewController.load(roomId: roomId, mode: .meet)
        pagecallWebViewController.modalPresentationStyle = .fullScreen
        present(pagecallWebViewController, animated: true)
    }
}
