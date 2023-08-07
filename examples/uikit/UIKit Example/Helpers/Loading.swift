//
//  Loading.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/28.
//

import Foundation
import UIKit

final class Loading: UIView {
    private let loadingLabel = UILabel()
    private let progressBar = ProgressBar()

    init() {
        super.init(frame: .zero)
        setUpLayout()
        configureDesign()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        self.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: PagecallViewConstants.Layout.ProgressViewLeftRightPadding),
            progressBar.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -PagecallViewConstants.Layout.ProgressViewLeftRightPadding),
            progressBar.bottomAnchor.constraint(equalTo: self.centerYAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.ProgressViewHeight)
        ])

        self.addSubview(loadingLabel)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loadingLabel.widthAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.LoadingLabelWidth),
            loadingLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: PagecallViewConstants.Layout.PaddingAboveLoadingLabel),
            loadingLabel.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.LoadingLabelHeight)
        ])
    }

    private func configureDesign() {
        self.backgroundColor = .white

        loadingLabel.textColor = PagecallViewConstants.Color.TextBlack
        loadingLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        loadingLabel.attributedText = NSMutableAttributedString(string: "Now Loading...", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        loadingLabel.sizeToFit()
    }

    func setProgress(progress: Float) {
        progressBar.setProgress(progress: progress)
    }
}
