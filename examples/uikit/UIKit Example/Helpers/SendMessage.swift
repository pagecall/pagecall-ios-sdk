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
    private let textField = UITextField()
    private let pagecallWebView: PagecallWebView

    init(pagecallWebView: PagecallWebView) {
        self.pagecallWebView = pagecallWebView
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
            textFieldBackground.heightAnchor.constraint(equalToConstant: 70),
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
            textFieldOverlay.leadingAnchor.constraint(equalTo: textFieldBackground.leadingAnchor, constant: 16),
            textFieldOverlay.trailingAnchor.constraint(equalTo: textFieldBackground.trailingAnchor, constant: -16),
            textFieldOverlay.topAnchor.constraint(equalTo: textFieldBackground.topAnchor, constant: 16),
            textFieldOverlay.bottomAnchor.constraint(equalTo: textFieldBackground.bottomAnchor, constant: -16)
        ])

        textFieldOverlay.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: textFieldOverlay.leadingAnchor, constant: 13),
            textField.trailingAnchor.constraint(equalTo: textFieldOverlay.trailingAnchor, constant: -13),
            textField.topAnchor.constraint(equalTo: textFieldOverlay.topAnchor, constant: 11),
            textField.bottomAnchor.constraint(equalTo: textFieldOverlay.bottomAnchor, constant: -11)
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
            pagecallWebView.sendMessage(message: message) { _ in
                self.textField.text = ""
                self.isHidden = true
            }
        }

        return false
    }
}
