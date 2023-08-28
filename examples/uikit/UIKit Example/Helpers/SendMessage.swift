//
//  SendMessage.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/27.
//

import Foundation
import UIKit
import Pagecall

final class SendMessage: UIView {
    private let backgroundView = UIView()
    private let textFieldBackground = UIView()
    private let textFieldOverlay = UIView()
    let textField = UITextField()
    private let sendMessage: (String, ((Error?) -> Void)?) -> Void

    init(sendMessage: @escaping (String, ((Error?) -> Void)?) -> Void) {
        self.sendMessage = sendMessage
        super.init(frame: .zero)
        setUpLayout()
        configureDesign()
        textField.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        self.addSubview(textFieldBackground)
        textFieldBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            textFieldBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            textFieldBackground.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.MessageTextFieldBackgroundHeight),
            textFieldBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        self.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: textFieldBackground.topAnchor)
        ])

        textFieldBackground.addSubview(textFieldOverlay)
        textFieldOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldOverlay.leadingAnchor.constraint(equalTo: textFieldBackground.leadingAnchor, constant: PagecallViewConstants.Layout.MessageTextFieldOverlayPadding),
            textFieldOverlay.trailingAnchor.constraint(equalTo: textFieldBackground.trailingAnchor, constant: -PagecallViewConstants.Layout.MessageTextFieldOverlayPadding),
            textFieldOverlay.topAnchor.constraint(equalTo: textFieldBackground.topAnchor, constant: PagecallViewConstants.Layout.MessageTextFieldOverlayPadding),
            textFieldOverlay.bottomAnchor.constraint(equalTo: textFieldBackground.bottomAnchor, constant: -PagecallViewConstants.Layout.MessageTextFieldOverlayPadding)
        ])

        textFieldOverlay.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: textFieldOverlay.leadingAnchor, constant: PagecallViewConstants.Layout.MessageTextFieldLeftRightPadding),
            textField.trailingAnchor.constraint(equalTo: textFieldOverlay.trailingAnchor, constant: -PagecallViewConstants.Layout.MessageTextFieldLeftRightPadding),
            textField.topAnchor.constraint(equalTo: textFieldOverlay.topAnchor, constant: PagecallViewConstants.Layout.MessageTextFieldUpDownPadding),
            textField.bottomAnchor.constraint(equalTo: textFieldOverlay.bottomAnchor, constant: -PagecallViewConstants.Layout.MessageTextFieldUpDownPadding)
        ])
    }

    private func configureDesign() {
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        textFieldBackground.backgroundColor = .white

        textFieldOverlay.layer.cornerRadius = 6
        textFieldOverlay.layer.borderWidth = 1
        textFieldOverlay.backgroundColor = .white
        textFieldOverlay.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor

        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
    }
}

extension SendMessage: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let message = textField.text {
            sendMessage(message) { _ in
                self.textField.text = ""
                self.endEditing(true)
                self.isHidden = true
            }
        }

        return false
    }
}
