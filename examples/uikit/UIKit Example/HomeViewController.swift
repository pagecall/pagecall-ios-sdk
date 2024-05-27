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
        static let SubviewHeight = CGFloat(76)
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
    let alert = Alert()

    let pagecallLogoView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Pagecall Logo")
        return imageView
    }()

    let roomSubview = LabelAndTextFieldView(labelText: "Room ID")
    let tokenSubview = LabelAndTextFieldView(labelText: "Access Token")
    let querySubview = LabelAndTextFieldView(labelText: "Query (Only for debug)")

    let enterButton = UIButton()
    let replayButton = UIButton()

    var innerViewTopConstraint: NSLayoutConstraint?
    var alertViewBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        configureDesign()
        buttonsAddTarget()

        addKeyboardNotifications()
        addTapGestures()

        // You can replace it with a desired value when testing.
        roomSubview.text = ""
        tokenSubview.text = ""
   }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.backgroundColor = HomeViewConstants.Color.LightGray
        alert.isHidden = true
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

        setUpRoomSubviewLayout()
        setUpTokenSubviewLayout()
        setUpQuerySubviewLayout()
        setUpButtonLayout()
        setUpAlertLayout()
    }

    func setUpRoomSubviewLayout() {
        innerView.addSubview(roomSubview)
        roomSubview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roomSubview.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            roomSubview.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            roomSubview.topAnchor.constraint(equalTo: pagecallLogoView.bottomAnchor, constant: 44),
            roomSubview.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.SubviewHeight)
        ])
    }

    func setUpTokenSubviewLayout() {
        innerView.addSubview(tokenSubview)
        tokenSubview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenSubview.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            tokenSubview.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            tokenSubview.topAnchor.constraint(equalTo: roomSubview.bottomAnchor, constant: HomeViewConstants.Layout.PaddingAboveLabel),
            tokenSubview.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.SubviewHeight)
        ])
    }

    func setUpQuerySubviewLayout() {
        innerView.addSubview(querySubview)
        querySubview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            querySubview.leadingAnchor.constraint(equalTo: innerView.leadingAnchor),
            querySubview.trailingAnchor.constraint(equalTo: innerView.trailingAnchor),
            querySubview.topAnchor.constraint(equalTo: tokenSubview.bottomAnchor, constant: HomeViewConstants.Layout.PaddingAboveLabel),
            querySubview.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.SubviewHeight)
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
        view.addSubview(alert)
        alert.translatesAutoresizingMaskIntoConstraints = false
        alertViewBottomConstraint = alert.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -HomeViewConstants.Layout.PaddingUnderAlert)
        NSLayoutConstraint.activate([
            alert.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: HomeViewConstants.Layout.LeftRightPadding),
            alert.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -HomeViewConstants.Layout.LeftRightPadding),
            alertViewBottomConstraint!,
            alert.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.AlertHeight)
        ])
    }

    func configureDesign() {
        view.backgroundColor = HomeViewConstants.Color.LightGray
        innerView.backgroundColor = HomeViewConstants.Color.LightGray
        topSafeAreaView.backgroundColor = HomeViewConstants.Color.LightGray

        configureButtonDesign()
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

    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension HomeViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
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

            if buttonBottom > keyboardTop { // when pushing up the innerView is necessary
                innerViewTopConstraint?.constant = innerViewTop - (buttonBottom - keyboardTop) - 16
            }

            alertViewBottomConstraint?.constant = safeAreaBottom - keyboardHeight - HomeViewConstants.Layout.PaddingUnderAlert
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // go back to original constraints
        let innerViewTop = HomeViewConstants.Layout.InnerViewTop

        innerViewTopConstraint?.constant = innerViewTop
        alertViewBottomConstraint?.constant = -HomeViewConstants.Layout.PaddingUnderAlert
    }

    private func openPagecall(mode: PagecallMode) {
        let queryItems = parseQueryItems()
        var vc: PagecallViewController?
        vc = PagecallViewController(roomId: roomSubview.text, accessToken: tokenSubview.text, mode: mode, queryItems: queryItems) { error in
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        self.navigationController?.pushViewController(vc!, animated: true)
    }

    @objc func onReplayButtonTap() {
        if roomSubview.text != "" && tokenSubview.text != "" {
            openPagecall(mode: .replay)
        } else {
            alert.isHidden = false
        }
    }

    @objc func onEnterButtonTap() {
        if roomSubview.text != "" && tokenSubview.text != "" {
            openPagecall(mode: .meet)
        } else {
            alert.isHidden = false
        }
    }

    func addTapGestures() {
        // dismiss keyboard when touched around
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    func parseQueryItems() -> [URLQueryItem]? {
        if querySubview.text != "" {
            return querySubview.text.components(separatedBy: "&")
                .map {
                    $0.components(separatedBy: "=")
                }
                .map {
                    URLQueryItem(name: $0[0], value: $0[1])
                }
        }
        return nil
    }
}
