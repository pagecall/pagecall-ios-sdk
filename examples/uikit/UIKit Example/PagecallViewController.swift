//
//  PagecallViewController.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/20.
//

import Foundation
import UIKit
import Pagecall

struct PagecallViewConstants {
    struct Layout {
        static let SafeAreaCover = CGFloat(100)
        static let ProgressViewLeftRightPadding = CGFloat(95)
        static let ProgressViewHeight = CGFloat(2)
        static let LoadingLabelWidth = CGFloat(112)
        static let LoadingLabelHeight = CGFloat(25)
        static let PaddingAboveLoadingLabel = CGFloat(13)
        static let PencilHeight = CGFloat(58)
        static let PencilWidth = CGFloat(56)
        static let MessageBoxLeftRightPadding = CGFloat(44)
        static let PaddingUnderMessageBox = CGFloat(24)
        static let MessageBoxHeight = CGFloat(60)
        static let MessageLabelLeftRightPadding = CGFloat(24)
        static let MessageLabelUpDownPadding = CGFloat(12)
        static let MessageTextFieldBackgroundHeight = CGFloat(70)
        static let MessageTextFieldOverlayPadding = CGFloat(16)
        static let MessageTextFieldLeftRightPadding = CGFloat(13)
        static let MessageTextFieldUpDownPadding = CGFloat(11)
    }

    struct Color {
        static let Navy = UIColor(red: 0.216, green: 0.255, blue: 0.318, alpha: 1)
        static let TextBlack = UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1)
        static let Blue = UIColor(red: 0.075, green: 0.38, blue: 1, alpha: 1)
        static let Gray = UIColor(red: 0.82, green: 0.836, blue: 0.86, alpha: 1)
    }
}

class PagecallViewController: UIViewController {
    let roomId: String
    let accessToken: String
    let queryItems: [URLQueryItem]?
    let mode: PagecallMode

    let topSafeAreaView = UIView()
    let loading = Loading()
    let messageBox = Message()

    let pagecallWebView = PagecallWebView()
    var sendMessage: SendMessage
    var sendMessageBottomConstraint: NSLayoutConstraint?
    let onFatalError: ((Error) -> Void)?

    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?, onFatalError: ((Error) -> Void)?) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.mode = mode
        self.queryItems = queryItems
        self.onFatalError = onFatalError
        self.sendMessage = SendMessage(sendMessage: pagecallWebView.sendMessage)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setUpNavigationBar()
        setUpLayout()
        configureDesign()
        addRightBarButton()
        addTapGestures()
        addKeyboardNotifications()
        enterRoom()
        pagecallWebView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })!
        keyWindow.addSubview(loading)
        loading.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loading.leadingAnchor.constraint(equalTo: keyWindow.leadingAnchor),
            loading.trailingAnchor.constraint(equalTo: keyWindow.trailingAnchor),
            loading.topAnchor.constraint(equalTo: keyWindow.topAnchor),
            loading.bottomAnchor.constraint(equalTo: keyWindow.bottomAnchor)
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        loading.removeFromSuperview()
        pagecallWebView.cleanup()
    }

    func setUpNavigationBar() {
        navigationController?.navigationBar.topItem?.title = ""
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.backgroundColor = PagecallViewConstants.Color.Navy
        navigationController?.navigationBar.isTranslucent = false
    }

    func setUpLayout() {
        view.addSubview(topSafeAreaView)
        topSafeAreaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topSafeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topSafeAreaView.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.SafeAreaCover)
        ])

        view.addSubview(pagecallWebView)
        pagecallWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagecallWebView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pagecallWebView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pagecallWebView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pagecallWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        sendMessageBottomConstraint = sendMessage.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        view.addSubview(sendMessage)
        sendMessage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sendMessage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sendMessage.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            sendMessage.topAnchor.constraint(equalTo: view.topAnchor),
            sendMessageBottomConstraint!
        ])

        view.addSubview(messageBox)
        messageBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PagecallViewConstants.Layout.MessageBoxLeftRightPadding),
            messageBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PagecallViewConstants.Layout.MessageBoxLeftRightPadding),
            messageBox.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -PagecallViewConstants.Layout.PaddingUnderMessageBox),
            messageBox.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.MessageBoxHeight)
        ])
    }

    func configureDesign() {
        topSafeAreaView.backgroundColor = PagecallViewConstants.Color.Navy
        messageBox.isHidden = true
        sendMessage.isHidden = true
    }

    func addRightBarButton() {
        let sendMessageButton = UIBarButtonItem(title: "sendMessage", style: .plain, target: self, action: #selector(sendMessageTapped))
        sendMessageButton.tintColor = .white

        navigationItem.rightBarButtonItem = sendMessageButton
    }

    func addTapGestures() {
        // dismiss keyboard when touched around
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func enterRoom() {
        loading.setProgress(progress: 0)
        if let queryItems = queryItems {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems)
        } else {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode)
        }
    }

}

extension PagecallViewController: PagecallDelegate {
    func pagecallDidTerminate(_ view: Pagecall.PagecallWebView, reason: Pagecall.TerminationReason) {
        loading.setProgress(progress: 1.0)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.loading.isHidden = true
        }
    }

    func pagecallDidEncounter(_ view: PagecallWebView, error: Error) {
        onFatalError?(error)
    }

    func pagecallDidReceive(_ view: PagecallWebView, message: String) {
        messageBox.setText(message: message)
        messageBox.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.messageBox.isHidden = true
        }
    }

    func pagecallDidLoad(_ view: PagecallWebView) {
        loading.setProgress(progress: 1)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.loading.isHidden = true
        }

    }

    func pagecallWillNavigate(_ view: PagecallWebView, url: String) {
        print("pagecallWillNavigate: \(url)")
    }

}

extension PagecallViewController {
    @objc private func sendMessageTapped() {
        sendMessage.textField.becomeFirstResponder()
        sendMessage.isHidden = false
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
        sendMessage.isHidden = true
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height

            sendMessageBottomConstraint?.constant = -keyboardHeight
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // go back to original constraints
        sendMessageBottomConstraint?.constant = 0
    }
}
