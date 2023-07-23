import UIKit
import Pagecall

struct HomeViewConstants {
    struct Layout {
        static let LeftRightPadding = CGFloat(32)
        static let UpDownPadding = CGFloat(44)
        static let InnerViewHeight = CGFloat(346)
        static let InnerViewTop = CGFloat(20)
        static let LogoWidth = CGFloat(128)
        static let LogoHeight = CGFloat(28)
        static let LabelHeight = CGFloat(24)
        static let TextFieldHeight = CGFloat(42)
        static let PaddingAboveLabel = CGFloat(20)
        static let PaddingAboveTextField = CGFloat(12)
        static let PaddingBtwLabelAndDivider = CGFloat(8)
        static let ButtonHeight = CGFloat(42)
        static let PaddingBtwButtons = CGFloat(24)
        static let SafeAreaCover = CGFloat(100)
        static let AlertHeight = CGFloat(56)
        static let AlertViewPadding = CGFloat(16)
        static let AlertLabelHeight = CGFloat(24)
        static let PaddingUnderAlert = CGFloat(40)
        static let PaddingBtwXImageAndAlertLabel = CGFloat(12)
        static let XImageHeight = CGFloat(20)
        static let XImageWidth = CGFloat(20)
    }
    
    struct Color {
        static let LightGray = UIColor(red: 0.976, green: 0.98, blue: 0.984, alpha: 1)
        static let BorderGray = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1)
        static let TextBlack = UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1)
        static let Blue = UIColor(red: 0.075, green: 0.38, blue: 1, alpha: 1)
        static let LightRed = UIColor(red: 0.996, green: 0.949, blue: 0.949, alpha: 1)
        static let BorderRed = UIColor(red: 0.887, green: 0.185, blue: 0.185, alpha: 0.5)
        static let TextRed = UIColor(red: 0.742, green: 0.096, blue: 0.096, alpha: 1)
    }
}

class HomeViewController: UIViewController {
    let innerView = UIView()
    let topSafeAreaView = UIView()
    let alertView = UIView()

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
    
    let alertLabel = UILabel()
    let circledXView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "circled X")
        return imageView
    }()
    let xView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "X")
        return imageView
    }()
    
    var innerViewTopConstraint: NSLayoutConstraint?
    var alertViewBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        configureDesign()
        buttonsAddTarget()
       
        addKeyboardNotifications()
        addTapGestures()
   }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.backgroundColor = HomeViewConstants.Color.LightGray
        alertView.isHidden = true
    }
    
    func setUpLayout() {
        view.addSubview(innerView)
        innerView.translatesAutoresizingMaskIntoConstraints = false
        innerViewTopConstraint = innerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: HomeViewConstants.Layout.InnerViewTop)
        
        NSLayoutConstraint.activate([
            innerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: HomeViewConstants.Layout.LeftRightPadding),
            innerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -HomeViewConstants.Layout.LeftRightPadding),
            innerViewTopConstraint!,
            innerView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.InnerViewHeight)
        ])
                
        view.addSubview(topSafeAreaView)
        topSafeAreaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topSafeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topSafeAreaView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.SafeAreaCover)
        ])
        
        innerView.addSubview(pagecallLogoView)
        pagecallLogoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagecallLogoView.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            pagecallLogoView.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.LogoWidth),
            pagecallLogoView.topAnchor.constraint(equalTo: innerView.topAnchor),
            pagecallLogoView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.LogoHeight)
        ])
        
        setUpRoomFieldLayout()
        setUpTokenFieldLayout()
        setUpQueryFieldLayout()
        setUpButtonLayout()
        setUpAlertLayout()
    }
    
    func setUpRoomFieldLayout() {
        innerView.addSubview(roomIdLabel)
        roomIdLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            roomIdLabel.widthAnchor.constraint(equalToConstant: 70),
            roomIdLabel.topAnchor.constraint(equalTo: pagecallLogoView.bottomAnchor, constant: HomeViewConstants.Layout.UpDownPadding),
            roomIdLabel.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.LabelHeight)
        ])
        
        innerView.addSubview(roomIdTextField)
        roomIdTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdTextField.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            roomIdTextField.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            roomIdTextField.topAnchor.constraint(equalTo: roomIdLabel.bottomAnchor, constant: HomeViewConstants.Layout.PaddingAboveTextField),
            roomIdTextField.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.TextFieldHeight)
        ])
        
        innerView.addSubview(roomIdDivider)
        roomIdDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomIdDivider.leadingAnchor.constraint(equalTo: roomIdLabel.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwLabelAndDivider),
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
            tokenLabel.widthAnchor.constraint(equalToConstant: 110),
            tokenLabel.topAnchor.constraint(equalTo: roomIdTextField.bottomAnchor, constant: HomeViewConstants.Layout.PaddingAboveLabel),
            tokenLabel.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.LabelHeight)
        ])

        innerView.addSubview(tokenTextField)
        tokenTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenTextField.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            tokenTextField.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            tokenTextField.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant:  HomeViewConstants.Layout.PaddingAboveTextField),
            tokenTextField.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.TextFieldHeight)
        ])

        innerView.addSubview(tokenDivider)
        tokenDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenDivider.leadingAnchor.constraint(equalTo: tokenLabel.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwLabelAndDivider),
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
            queryLabel.widthAnchor.constraint(equalToConstant: 185),
            queryLabel.topAnchor.constraint(equalTo: tokenTextField.bottomAnchor, constant: HomeViewConstants.Layout.PaddingAboveLabel),
            queryLabel.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.LabelHeight)
        ])
        
        innerView.addSubview(queryTextField)
        queryTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            queryTextField.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            queryTextField.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            queryTextField.topAnchor.constraint(equalTo: queryLabel.bottomAnchor, constant:  HomeViewConstants.Layout.PaddingAboveTextField),
            queryTextField.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.TextFieldHeight)
        ])

        innerView.addSubview(queryDivider)
        queryDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            queryDivider.leadingAnchor.constraint(equalTo: queryLabel.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwLabelAndDivider),
            queryDivider.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            queryDivider.centerYAnchor.constraint(equalTo: queryLabel.centerYAnchor),
            queryDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setUpButtonLayout() {
        view.addSubview(replayButton)
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            replayButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: HomeViewConstants.Layout.LeftRightPadding),
            replayButton.widthAnchor.constraint(equalToConstant: (self.view.frame.size.width - HomeViewConstants.Layout.LeftRightPadding*2 - HomeViewConstants.Layout.PaddingBtwButtons)/2),
            replayButton.topAnchor.constraint(equalTo: innerView.bottomAnchor, constant: HomeViewConstants.Layout.UpDownPadding),
            replayButton.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.ButtonHeight)
        ])
        
        view.addSubview(enterButton)
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            enterButton.leadingAnchor.constraint(equalTo: replayButton.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwButtons),
            enterButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -HomeViewConstants.Layout.LeftRightPadding),
            enterButton.topAnchor.constraint(equalTo: innerView.bottomAnchor, constant: HomeViewConstants.Layout.UpDownPadding),
            enterButton.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.ButtonHeight)
        ])
    }
    
    func setUpAlertLayout() {
        view.addSubview(alertView)
        alertView.translatesAutoresizingMaskIntoConstraints = false
        alertViewBottomConstraint = alertView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -HomeViewConstants.Layout.PaddingUnderAlert)
        NSLayoutConstraint.activate([
            alertView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: HomeViewConstants.Layout.LeftRightPadding),
            alertView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -HomeViewConstants.Layout.LeftRightPadding),
            alertViewBottomConstraint!,
            alertView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.AlertHeight)
        ])
        
        alertView.addSubview(circledXView)
        circledXView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circledXView.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: HomeViewConstants.Layout.AlertViewPadding),
            circledXView.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageWidth),
            circledXView.centerYAnchor.constraint(equalTo: alertView.centerYAnchor),
            circledXView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageHeight)
        ])

        alertView.addSubview(xView)
        xView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            xView.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageWidth),
            xView.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -HomeViewConstants.Layout.AlertViewPadding),
            xView.centerYAnchor.constraint(equalTo: alertView.centerYAnchor),
            xView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageHeight)
        ])
        
        alertView.addSubview(alertLabel)
        alertLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            alertLabel.leadingAnchor.constraint(equalTo: circledXView.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwXImageAndAlertLabel),
            alertLabel.trailingAnchor.constraint(equalTo: xView.leadingAnchor, constant: -HomeViewConstants.Layout.PaddingBtwXImageAndAlertLabel),
            alertLabel.centerYAnchor.constraint(equalTo: alertView.centerYAnchor),
            alertLabel.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.AlertLabelHeight)
        ])
    }

    func configureDesign() {
        view.backgroundColor = HomeViewConstants.Color.LightGray
        innerView.backgroundColor = HomeViewConstants.Color.LightGray
        topSafeAreaView.backgroundColor = HomeViewConstants.Color.LightGray

        configureRoomFieldDesign()
        configureTokenFieldDesign()
        configureQueryFieldDesign()
        configureButtonDesign()
        configureAlertDesign()
    }

    func configureRoomFieldDesign() {
        roomIdLabel.textColor = HomeViewConstants.Color.TextBlack
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
        roomIdTextField.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor
        
        roomIdDivider.layer.borderWidth = 1
        roomIdDivider.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor
    }

    func configureTokenFieldDesign() {
        tokenLabel.textColor = HomeViewConstants.Color.TextBlack
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
        tokenTextField.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor

        tokenDivider.layer.borderWidth = 1
        tokenDivider.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor
    }
    
    func configureQueryFieldDesign() {
        queryLabel.textColor = HomeViewConstants.Color.TextBlack
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
        queryTextField.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor

        queryDivider.layer.borderWidth = 1
        queryDivider.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor
    }
    
    func configureButtonDesign() {
        replayButton.backgroundColor = .white
        replayButton.layer.cornerRadius = 6
        replayButton.layer.borderWidth = 1
        replayButton.layer.borderColor = HomeViewConstants.Color.Blue.cgColor
        
        replayButton.setTitleColor(HomeViewConstants.Color.Blue, for: .normal)
        replayButton.setTitle("Replay", for: .normal)
        replayButton.titleLabel?.font = UIFont(name: "Pretendard-Medium", size: 14)
        
        enterButton.backgroundColor = HomeViewConstants.Color.Blue
        enterButton.layer.cornerRadius = 6
        
        enterButton.setTitleColor(.white, for: .normal)
        enterButton.setTitle("Enter Room", for: .normal)
        enterButton.titleLabel?.font = UIFont(name: "Pretendard-Medium", size: 14)
    }
    
    func buttonsAddTarget() {
        replayButton.addTarget(self, action: #selector(onReplayButtonTap), for: .touchUpInside)
        enterButton.addTarget(self, action: #selector(onEnterButtonTap), for: .touchUpInside)
    }
    
    func configureAlertDesign() {
        alertView.layer.backgroundColor = HomeViewConstants.Color.LightRed.cgColor
        alertView.layer.cornerRadius = 6
        alertView.layer.borderWidth = 1
        alertView.layer.borderColor = HomeViewConstants.Color.BorderRed.cgColor
        
        alertLabel.textColor = HomeViewConstants.Color.TextRed
        alertLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        alertLabel.attributedText = NSMutableAttributedString(string: "입력 값이 필요합니다.", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }
    
    func addTapGestures() {
        //dismiss keyboard when touched around
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissAlert))
        xView.addGestureRecognizer(tapGesture)
        xView.isUserInteractionEnabled = true
    }
    
    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension HomeViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func dismissAlert() {
        alertView.isHidden = true
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            let window = UIApplication.shared.windows.first
            let safeAreaBottom = (window != nil) ? window!.safeAreaInsets.bottom : 0
            let safeAreaTop = (window != nil) ? window!.safeAreaInsets.top : 0
            let safeAreaHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
            
            let buttonBottom = HomeViewConstants.Layout.InnerViewHeight + HomeViewConstants.Layout.UpDownPadding + HomeViewConstants.Layout.ButtonHeight
            let innerViewTop = HomeViewConstants.Layout.InnerViewTop

            let keyboardTop = safeAreaHeight - keyboardHeight - safeAreaTop + safeAreaBottom
            
            if (buttonBottom > keyboardTop) { //when pushing up the innerView is necessary
                innerViewTopConstraint?.constant = innerViewTop - (buttonBottom - keyboardTop) - 16
            }
            
            alertViewBottomConstraint?.constant = safeAreaBottom - keyboardHeight - HomeViewConstants.Layout.PaddingUnderAlert
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        //go back to original constraints
        let innerViewTop = HomeViewConstants.Layout.InnerViewTop
        
        innerViewTopConstraint?.constant = innerViewTop
        alertViewBottomConstraint?.constant = -HomeViewConstants.Layout.PaddingUnderAlert
    }
    
    @objc func onReplayButtonTap() {
        if (roomIdTextField.text != "" && tokenTextField.text != "") {
            let queryItems = parseQueryItems()
            let vc = PagecallViewController(roomId: roomIdTextField.text!, accessToken: tokenTextField.text!, mode: .replay, queryItems: queryItems)
            
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            alertView.isHidden = false
        }
    }
    
    @objc func onEnterButtonTap() {
        if (roomIdTextField.text != "" && tokenTextField.text != "") {
            let queryItems = parseQueryItems()
            let vc = PagecallViewController(roomId: roomIdTextField.text!, accessToken: tokenTextField.text!, mode: .meet, queryItems: queryItems)

            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            alertView.isHidden = false
        }
    }
    
    func parseQueryItems() -> [URLQueryItem]? {
        if (queryTextField.text != "") {
            if let queryText = queryTextField.text {
                return queryText.components(separatedBy: "&")
                    .map {
                        $0.components(separatedBy: "=")
                    }
                    .map {
                        URLQueryItem(name: $0[0], value: $0[1])
                    }
            }
        }
        return nil
    }
}
