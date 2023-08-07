//
//  AlertView.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/24.
//

import Foundation
import UIKit

final class Alert: UIView {
    private let label = UILabel()

    private let circledX: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "circled X")
        return imageView
    }()

    private let x: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "X")
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        configure()
        setUpLayout()
        addTapGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        self.layer.backgroundColor = HomeViewConstants.Color.LightRed.cgColor
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 1
        self.layer.borderColor = HomeViewConstants.Color.BorderRed.cgColor

        label.textColor = HomeViewConstants.Color.TextRed
        label.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        label.attributedText = NSMutableAttributedString(string: "An input value is required.", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }

    func setUpLayout() {
        self.addSubview(circledX)
        circledX.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circledX.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: HomeViewConstants.Layout.AlertViewPadding),
            circledX.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageWidth),
            circledX.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            circledX.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageHeight)
        ])

        self.addSubview(x)
        x.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            x.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageWidth),
            x.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -HomeViewConstants.Layout.AlertViewPadding),
            x.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            x.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageHeight)
        ])

        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: circledX.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwXImageAndAlertLabel),
            label.trailingAnchor.constraint(equalTo: x.leadingAnchor, constant: -HomeViewConstants.Layout.PaddingBtwXImageAndAlertLabel),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            label.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.AlertLabelHeight)
        ])
    }

    func addTapGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissAlert))
        x.addGestureRecognizer(tapGesture)
        x.isUserInteractionEnabled = true
    }

    @objc func dismissAlert() {
        self.isHidden = true
    }
}
