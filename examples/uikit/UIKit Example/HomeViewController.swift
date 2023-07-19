import UIKit
import Pagecall

struct EmojiMessage: Codable {
    let emoji: String
    let sender: String
}

class HomeViewController: UIViewController {
    let innerView = UIView()

    let pagecallLogoView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Pagecall Logo")
        return imageView
    }()

    let roomIdLabel = UILabel()
    let roomIdTextField = UITextField()
    let roomIdDivider = UIView()

    let tokenLabel = UILabel()
    let tokenTextField = UITextField()
    let tokenDivider = UIView()

    let queryLabel = UILabel()
    let queryTextField = UITextField()
    let queryDivider = UIView()

    let enterButton = UIButton()
    let replayButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        configureDesign()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }

    func setUpLayout() {
        view.addSubview(innerView)
        innerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            innerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            innerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            innerView.heightAnchor.constraint(equalToConstant: 334)
        ])
        innerView.addSubview(pagecallLogoView)
        pagecallLogoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagecallLogoView.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            pagecallLogoView.widthAnchor.constraint(equalToConstant: 128),
            pagecallLogoView.topAnchor.constraint(equalTo: innerView.topAnchor),
            pagecallLogoView.heightAnchor.constraint(equalToConstant: 28)
        ])
        setUpRoomFieldLayout()
        setUpTokenFieldLayout()
        setUpQueryFieldLayout()
        setUpButtonLayout()
    }
    
    func setUpRoomFieldLayout() {
        innerView.addSubview(roomIdLabel)
        roomIdLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            roomIdLabel.widthAnchor.constraint(equalToConstant: 65),
            roomIdLabel.topAnchor.constraint(equalTo: pagecallLogoView.bottomAnchor, constant: 44),
            roomIdLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        innerView.addSubview(roomIdTextField)
        roomIdTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdTextField.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            roomIdTextField.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            roomIdTextField.topAnchor.constraint(equalTo: roomIdLabel.bottomAnchor, constant: 12),
            roomIdTextField.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        innerView.addSubview(roomIdDivider)
        roomIdDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdDivider.leadingAnchor.constraint(equalTo: roomIdLabel.trailingAnchor, constant: 8),
            roomIdDivider.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            roomIdDivider.centerYAnchor.constraint(equalTo: roomIdLabel.centerYAnchor),
            roomIdDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setUpTokenFieldLayout() {
        innerView.addSubview(tokenLabel)
        tokenLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            tokenLabel.widthAnchor.constraint(equalToConstant: 105),
            tokenLabel.topAnchor.constraint(equalTo: roomIdTextField.bottomAnchor, constant: 20),
            tokenLabel.heightAnchor.constraint(equalToConstant: 24)
        ])

        innerView.addSubview(tokenTextField)
        tokenTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenTextField.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            tokenTextField.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            tokenTextField.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant: 12),
            tokenTextField.heightAnchor.constraint(equalToConstant: 42)
        ])

        innerView.addSubview(tokenDivider)
        tokenDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenDivider.leadingAnchor.constraint(equalTo: tokenLabel.trailingAnchor, constant: 8),
            tokenDivider.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            tokenDivider.centerYAnchor.constraint(equalTo: tokenLabel.centerYAnchor),
            tokenDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setUpQueryFieldLayout() {
        innerView.addSubview(queryLabel)
        queryLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            queryLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            queryLabel.widthAnchor.constraint(equalToConstant: 175),
            queryLabel.topAnchor.constraint(equalTo: tokenTextField.bottomAnchor, constant: 20),
            queryLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        innerView.addSubview(queryTextField)
        queryTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            queryTextField.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            queryTextField.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            queryTextField.topAnchor.constraint(equalTo: queryLabel.bottomAnchor, constant: 12),
            queryTextField.heightAnchor.constraint(equalToConstant: 42)
        ])

        innerView.addSubview(queryDivider)
        queryDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            queryDivider.leadingAnchor.constraint(equalTo: queryLabel.trailingAnchor, constant: 8),
            queryDivider.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            queryDivider.centerYAnchor.constraint(equalTo: queryLabel.centerYAnchor),
            queryDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setUpButtonLayout() {
        
    }

    func configureDesign() {
        view.backgroundColor = UIColor(red: 0.976, green: 0.98, blue: 0.984, alpha: 1)
        innerView.backgroundColor = UIColor(red: 0.976, green: 0.98, blue: 0.984, alpha: 1)
        
        configureRoomFieldDesign()
        configureTokenFieldDesign()
        configureQueryFieldDesign()
        configureButtonDesign()
    }

    func configureRoomFieldDesign() {
        roomIdLabel.textColor = UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1)
        roomIdLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        roomIdLabel.attributedText = NSMutableAttributedString(string: "Room ID", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        roomIdLabel.sizeToFit()
        
        roomIdTextField.autocapitalizationType = .none
        roomIdTextField.autocorrectionType = .no
        roomIdTextField.backgroundColor = .white
        roomIdTextField.layer.cornerRadius = 6
        roomIdTextField.layer.borderWidth = 1
        roomIdTextField.layer.borderColor = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1).cgColor

        
        roomIdDivider.layer.borderWidth = 1
        roomIdDivider.layer.borderColor = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1).cgColor
    }

    func configureTokenFieldDesign() {
        tokenLabel.textColor = UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1)
        tokenLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        tokenLabel.attributedText = NSMutableAttributedString(string: "Access Token", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        tokenLabel.sizeToFit()
        
        tokenTextField.autocapitalizationType = .none
        tokenTextField.autocorrectionType = .no
        tokenTextField.backgroundColor = .white
        tokenTextField.layer.cornerRadius = 6
        tokenTextField.layer.borderWidth = 1
        tokenTextField.layer.borderColor = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1).cgColor

        tokenDivider.layer.borderWidth = 1
        tokenDivider.layer.borderColor = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1).cgColor
    }
    
    func configureQueryFieldDesign() {
        queryLabel.textColor = UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1)
        queryLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        queryLabel.attributedText = NSMutableAttributedString(string: "Query (Only for debug)", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        queryLabel.sizeToFit()
        
        queryTextField.autocapitalizationType = .none
        queryTextField.autocorrectionType = .no
        queryTextField.backgroundColor = .white
        queryTextField.layer.cornerRadius = 6
        queryTextField.layer.borderWidth = 1
        queryTextField.layer.borderColor = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1).cgColor

        queryDivider.layer.borderWidth = 1
        queryDivider.layer.borderColor = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1).cgColor
    }
    
    func configureButtonDesign() {
        
    }
}

// extension ViewController: PagecallDelegate {
//    func pagecallDidTerminate(_ view: Pagecall.PagecallWebView, reason: Pagecall.TerminationReason) {
//        DispatchQueue.main.async {
//            self.progressView.setProgress(0, animated: true)
//        }
//    }
//
//    func pagecallDidEncounter(_ view: PagecallWebView, error: Error) {
//        DispatchQueue.main.async {
//            self.progressView.setProgress(0.25, animated: true)
//        }
//    }
//
//    func pagecallDidLoad(_ view: PagecallWebView) {
//        DispatchQueue.main.async {
//            self.progressView.setProgress(1, animated: true)
//        }
//    }
// }

extension HomeViewController {
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}
