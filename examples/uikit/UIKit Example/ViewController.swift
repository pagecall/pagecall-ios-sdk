import UIKit
import Pagecall

struct EmojiMessage: Codable {
    let emoji: String
    let sender: String
}

class ViewController: UIViewController {
    @IBOutlet weak var progressView: UIProgressView!
    let pagecallWebView = PagecallWebView()

    override func viewDidLoad() {
        super.viewDidLoad()
        pagecallWebView.delegate = self
        progressView.setProgress(0, animated: false)

        view.addSubview(pagecallWebView)

        pagecallWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagecallWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagecallWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagecallWebView.topAnchor.constraint(equalTo: roomIdField.bottomAnchor, constant: 50),
            pagecallWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @IBOutlet weak var roomIdField: UITextField!

    @IBAction func enterTapped(_ sender: Any) {
        guard let roomId = roomIdField.text else { return }
        if roomId.isEmpty { return }

        progressView.setProgress(0.5, animated: false)
        _ = pagecallWebView.load(roomId: roomId, mode: .meet)
    }
}

extension ViewController: PagecallDelegate {
    func pagecallDidTerminate(_ view: Pagecall.PagecallWebView, reason: Pagecall.TerminationReason) {
        DispatchQueue.main.async {
            self.progressView.setProgress(0, animated: true)
        }
    }

    func pagecallDidEncounter(_ view: PagecallWebView, error: Error) {
        DispatchQueue.main.async {
            self.progressView.setProgress(0.25, animated: true)
        }
    }

    func pagecallDidLoad(_ view: PagecallWebView) {
        DispatchQueue.main.async {
            self.progressView.setProgress(1, animated: true)
        }
    }
}
