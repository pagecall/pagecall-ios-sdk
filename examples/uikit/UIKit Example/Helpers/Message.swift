//
//  Message.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/27.
//

import Foundation
import UIKit

final class Message: UIView {
    private let rectangle = UIView()
    private let messageLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setUpLayout()
        configureDesign()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        self.addSubview(rectangle)
        rectangle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rectangle.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            rectangle.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            rectangle.topAnchor.constraint(equalTo: self.topAnchor),
            rectangle.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        rectangle.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: rectangle.leadingAnchor, constant: PagecallViewConstants.Layout.MessageLabelLeftRightPadding),
            messageLabel.trailingAnchor.constraint(equalTo: rectangle.trailingAnchor, constant: -PagecallViewConstants.Layout.MessageLabelLeftRightPadding),
            messageLabel.topAnchor.constraint(equalTo: rectangle.topAnchor, constant: PagecallViewConstants.Layout.MessageLabelUpDownPadding),
            messageLabel.bottomAnchor.constraint(equalTo: rectangle.bottomAnchor, constant: -PagecallViewConstants.Layout.MessageLabelUpDownPadding)
        ])
    }

    private func configureDesign() {
        rectangle.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        rectangle.layer.cornerRadius = 6

        messageLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        messageLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.19
        messageLabel.attributedText = NSMutableAttributedString(string: "바로 focused 되어야 합니다", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }

    func setText(message: String) {
        messageLabel.text = message
    }
}
