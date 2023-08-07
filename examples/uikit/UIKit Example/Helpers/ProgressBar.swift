//
//  ProgressBar.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/28.
//

import Foundation
import UIKit

final class ProgressBar: UIView {
    private let background = UIView()
    private let bar = UIView()
    private let pencil: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Pencil")
        return imageView
    }()

    private var barTrailingConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        setUpLayout()
        configureDesign()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        self.addSubview(background)
        background.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            background.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            background.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.ProgressViewHeight)
        ])

        barTrailingConstraint = bar.trailingAnchor.constraint(equalTo: self.leadingAnchor)
        self.addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            barTrailingConstraint!,
            bar.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            bar.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.ProgressViewHeight)
        ])

        self.addSubview(pencil)
        pencil.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pencil.widthAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.PencilWidth),
            pencil.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -13), // -13 necessary because of the image shape
            pencil.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -2), // -2 necessary because of the image shape
            pencil.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.PencilHeight)
        ])
    }

    private func configureDesign() {
        background.backgroundColor = PagecallViewConstants.Color.Gray
        background.layer.cornerRadius = 3
        bar.backgroundColor = PagecallViewConstants.Color.Blue
        bar.layer.cornerRadius = 3
    }

    func setProgress(progress: Float) {
        self.barTrailingConstraint?.constant = self.frame.width * CGFloat(progress)
    }
}
