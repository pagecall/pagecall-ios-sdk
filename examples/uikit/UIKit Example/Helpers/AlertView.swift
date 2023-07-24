//
//  AlertView.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/24.
//

import Foundation
import UIKit

final class AlertView: UIView {
    private let label = UILabel()

    private let circledXView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "circled X")
        return imageView
    }()

    private let xView: UIImageView = {
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
        label.attributedText = NSMutableAttributedString(string: "입력 값이 필요합니다.", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }

    func setUpLayout() {
        self.addSubview(circledXView)
        circledXView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circledXView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: HomeViewConstants.Layout.AlertViewPadding),
            circledXView.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageWidth),
            circledXView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            circledXView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageHeight)
        ])

        self.addSubview(xView)
        xView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            xView.widthAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageWidth),
            xView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -HomeViewConstants.Layout.AlertViewPadding),
            xView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            xView.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.XImageHeight)
        ])

        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: circledXView.trailingAnchor, constant: HomeViewConstants.Layout.PaddingBtwXImageAndAlertLabel),
            label.trailingAnchor.constraint(equalTo: xView.leadingAnchor, constant: -HomeViewConstants.Layout.PaddingBtwXImageAndAlertLabel),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            label.heightAnchor.constraint(equalToConstant: HomeViewConstants.Layout.AlertLabelHeight)
        ])
    }

    func addTapGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissAlert))
        xView.addGestureRecognizer(tapGesture)
        xView.isUserInteractionEnabled = true
    }

    @objc func dismissAlert() {
        self.isHidden = true
    }
}
