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
    
    var enterButtonBottomConstraint: NSLayoutConstraint?
    var replayButtonBottomConstraint: NSLayoutConstraint?
    var innerViewTopConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        configureDesign()
        buttonsAddTarget()
        
        //dismiss keyboard when touched around
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
       
        addKeyboardNotifications()
   }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeKeyboardNotifications()
    }

    func setUpLayout() {
        view.addSubview(innerView)
        innerView.translatesAutoresizingMaskIntoConstraints = false
        innerViewTopConstraint = innerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        
        NSLayoutConstraint.activate([
            innerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            innerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            innerViewTopConstraint!,
            innerView.heightAnchor.constraint(equalToConstant: 346)
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
        view.addSubview(replayButton)
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        replayButtonBottomConstraint = replayButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        NSLayoutConstraint.activate([
            replayButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            replayButton.widthAnchor.constraint(equalToConstant: (self.view.frame.size.width - 32*2 - 24)/2),
            replayButtonBottomConstraint!,
            replayButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        view.addSubview(enterButton)
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        enterButtonBottomConstraint = enterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        NSLayoutConstraint.activate([
            enterButton.leadingAnchor.constraint(equalTo: replayButton.trailingAnchor, constant: 24),
            enterButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            enterButtonBottomConstraint!,
            enterButton.heightAnchor.constraint(equalToConstant: 42)
        ])
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
        replayButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        replayButton.layer.cornerRadius = 6
        replayButton.layer.borderWidth = 1
        replayButton.layer.borderColor = UIColor(red: 0.075, green: 0.38, blue: 1, alpha: 1).cgColor
        
        replayButton.setTitleColor(UIColor(red: 0.075, green: 0.38, blue: 1, alpha: 1), for: .normal)
        replayButton.setTitle("Replay", for: .normal)
        replayButton.titleLabel?.font = UIFont(name: "Pretendard-Medium", size: 14)
        
        enterButton.backgroundColor = UIColor(red: 0.075, green: 0.38, blue: 1, alpha: 1)
        enterButton.layer.cornerRadius = 6
        
        enterButton.setTitleColor(UIColor(red: 0.976, green: 0.98, blue: 0.984, alpha: 1), for: .normal)
        enterButton.setTitle("Enter Room", for: .normal)
        enterButton.titleLabel?.font = UIFont(name: "Pretendard-Medium", size: 14)
    }
    
    func buttonsAddTarget() {
        replayButton.addTarget(self, action: #selector(onReplayButtonTap), for: .touchUpInside)
        enterButton.addTarget(self, action: #selector(onEnterButtonTap), for: .touchUpInside)
    }
    
    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension HomeViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            let buttonHeight = CGFloat(42)
            let innerViewHeight = CGFloat(346)
            let innerViewTop = CGFloat(20)

            replayButtonBottomConstraint?.constant = -keyboardHeight
            enterButtonBottomConstraint?.constant = -keyboardHeight
            
            let safeAreaHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
            
            let buttonTopWhenKeyboardEnabled = safeAreaHeight - (keyboardHeight + buttonHeight)
            
            let innerViewBottom = innerViewTop + innerViewHeight
            
            if (innerViewBottom > buttonTopWhenKeyboardEnabled) { //when pushing up the innerView is necessary (button covering the text field)
                innerViewTopConstraint?.constant = innerViewTop - (innerViewBottom - buttonTopWhenKeyboardEnabled) - 16
            }
            
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        //go back to original constraints
        let buttonBottom = CGFloat(24)
        let innerViewTop = CGFloat(20)
        
        replayButtonBottomConstraint?.constant = -buttonBottom
        enterButtonBottomConstraint?.constant = -buttonBottom
        innerViewTopConstraint?.constant = innerViewTop
    }
    
    @objc func onReplayButtonTap() {
        if let roomId = roomIdTextField.text, let accessToken = tokenTextField.text {
            let vc = PagecallViewController(roomId: roomId, accessToken: accessToken, mode: .replay)
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func onEnterButtonTap() {
        if let roomId = roomIdTextField.text, let accessToken = tokenTextField.text {
            let vc = PagecallViewController(roomId: roomId, accessToken: accessToken, mode: .meet)
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
