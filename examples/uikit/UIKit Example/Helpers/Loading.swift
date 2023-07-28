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
    private let progressView = UIProgressView()
    private let pencilImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Pencil")
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        setUpLayout()
        configureDesign()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        self.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: PagecallViewConstants.Layout.ProgressViewLeftRightPadding),
            progressView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -PagecallViewConstants.Layout.ProgressViewLeftRightPadding),
            progressView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            progressView.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.ProgressViewHeight)
        ])

        self.addSubview(loadingLabel)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loadingLabel.widthAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.LoadingLabelWidth),
            loadingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: PagecallViewConstants.Layout.PaddingAboveLoadingLabel),
            loadingLabel.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.LoadingLabelHeight)
        ])

        self.addSubview(pencilImageView)
        pencilImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pencilImageView.widthAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.PencilWidth),
            pencilImageView.leadingAnchor.constraint(equalTo: progressView.leadingAnchor),
            pencilImageView.bottomAnchor.constraint(equalTo: progressView.topAnchor),
            pencilImageView.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.PencilHeight)
        ])
    }

    private func configureDesign() {
        self.backgroundColor = .white
        progressView.progressTintColor = PagecallViewConstants.Color.Blue

        loadingLabel.textColor = PagecallViewConstants.Color.TextBlack
        loadingLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        loadingLabel.attributedText = NSMutableAttributedString(string: "Now Loading...", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        loadingLabel.sizeToFit()
    }

    func setProgress(progress: Float) {
        progressView.setProgress(progress, animated: true)
    }

    func movePencil() {
        UIView.animate(withDuration: 1.1, delay: 0, options: [], animations: {
            self.pencilImageView.center.x += self.frame.width - 2*PagecallViewConstants.Layout.ProgressViewLeftRightPadding
        })
    }
}
