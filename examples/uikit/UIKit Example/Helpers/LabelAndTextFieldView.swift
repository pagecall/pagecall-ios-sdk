//
//  LabelAndTextFieldView.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/24.
//

import Foundation
import UIKit

final class LabelAndTextFieldView: UIView {
    private let label = UILabel()
    private let textField = UITextField()
    private let textFieldOverlay = UIView()
    private let divider = UIView()

    var text: String {
        get {
            return textField.text!
        }
        set {
            textField.text = newValue
        }
    }

    init(labelText: String) {
        super.init(frame: .zero)
        configure(labelText: labelText)
        setUpLayout()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(labelText: String) {
        label.textColor = HomeViewConstants.Color.TextBlack
        label.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        label.attributedText = NSMutableAttributedString(string: labelText, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        label.sizeToFit()

        textFieldOverlay.layer.cornerRadius = 6
        textFieldOverlay.layer.borderWidth = 1
        textFieldOverlay.backgroundColor = .white
        textFieldOverlay.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor

        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .white
        textField.overrideUserInterfaceStyle = .light

        divider.layer.borderWidth = 1
        divider.layer.borderColor = HomeViewConstants.Color.BorderGray.cgColor
    }

    func setUpLayout() {
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.LabelHeight)
        ])

        self.addSubview(textFieldOverlay)
        textFieldOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldOverlay.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            textFieldOverlay.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            textFieldOverlay.topAnchor.constraint(equalTo: label.bottomAnchor, constant: HomeViewConstants.Layout.PaddingAboveTextField),
            textFieldOverlay.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.TextFieldHeight)
        ])

        textFieldOverlay.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: textFieldOverlay.leadingAnchor, constant: 13),
            textField.trailingAnchor.constraint(equalTo: textFieldOverlay.trailingAnchor, constant: -13),
            textField.topAnchor.constraint(equalTo: textFieldOverlay.topAnchor, constant: 11),
            textField.bottomAnchor.constraint(equalTo: textFieldOverlay.bottomAnchor, constant: -11)
        ])

        self.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwLabelAndDivider),
            divider.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            divider.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
