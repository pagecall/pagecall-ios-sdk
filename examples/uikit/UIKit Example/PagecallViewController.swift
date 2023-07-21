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
    }
    
    struct Color {
        static let Navy = UIColor(red: 0.216, green: 0.255, blue: 0.318, alpha: 1)
        static let TextBlack = UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1)
        static let Blue = UIColor(red: 0.075, green: 0.38, blue: 1, alpha: 1)
    }
}

class PagecallViewController: UIViewController {
    let roomId: String
    let accessToken: String
    let queryItems: [URLQueryItem]?
    let mode: PagecallMode
    
    let loadingView = UIView()
    let topSafeAreaView = UIView()
    let loadingLabel = UILabel()
    let progressView = UIProgressView()
    
    let pencilImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Pencil")
        return imageView
    }()
    
    let pagecallWebView = PagecallWebView()
    
    init(roomId: String, accessToken: String, mode: PagecallMode, queryItems: [URLQueryItem]?) {
        self.roomId = roomId
        self.accessToken = accessToken
        self.mode = mode
        self.queryItems = queryItems
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setUpNavigationBar()
        setUpLayout()
        configureDesign()
        pagecallWebView.delegate = self
        enterRoom()
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
        
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })!
        keyWindow.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.leadingAnchor.constraint(equalTo: keyWindow.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: keyWindow.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: keyWindow.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: keyWindow.bottomAnchor)
        ])
        
        loadingView.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: PagecallViewConstants.Layout.ProgressViewLeftRightPadding),
            progressView.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -PagecallViewConstants.Layout.ProgressViewLeftRightPadding),
            progressView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            progressView.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.ProgressViewHeight)
        ])
        
        loadingView.addSubview(loadingLabel)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.widthAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.LoadingLabelWidth),
            loadingLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: PagecallViewConstants.Layout.PaddingAboveLoadingLabel),
            loadingLabel.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.LoadingLabelHeight)
        ])
        
        loadingView.addSubview(pencilImageView)
        pencilImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pencilImageView.widthAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.PencilWidth),
            pencilImageView.leadingAnchor.constraint(equalTo: progressView.leadingAnchor),
            pencilImageView.bottomAnchor.constraint(equalTo: progressView.topAnchor),
            pencilImageView.heightAnchor.constraint(equalToConstant: PagecallViewConstants.Layout.PencilHeight)
        ])
    }
    
    func configureDesign() {
        loadingView.backgroundColor = .white
        topSafeAreaView.backgroundColor = PagecallViewConstants.Color.Navy
        progressView.progressTintColor = PagecallViewConstants.Color.Blue
        
        loadingLabel.textColor = PagecallViewConstants.Color.TextBlack
        loadingLabel.font = UIFont(name: "Pretendard-Medium", size: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        loadingLabel.attributedText = NSMutableAttributedString(string: "Now Loading...", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        loadingLabel.sizeToFit()
    }
    
    func enterRoom() {
        progressView.setProgress(0.0, animated: true)
        if let queryItems = queryItems {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode, queryItems: queryItems)
        } else {
            _ = pagecallWebView.load(roomId: roomId, accessToken: accessToken, mode: mode)
        }
    }
    
    func movePencil() {
        UIView.animate(withDuration: 1.1, delay: 0, options: [], animations: {
            self.pencilImageView.center.x += self.view.frame.width - 2*PagecallViewConstants.Layout.ProgressViewLeftRightPadding
        })
    }
}

extension PagecallViewController: PagecallDelegate {
    func pagecallDidTerminate(_ view: Pagecall.PagecallWebView, reason: Pagecall.TerminationReason) {
        movePencil()
        self.progressView.setProgress(1, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            self.loadingView.isHidden = true
        }
    
    }

    func pagecallDidEncounter(_ view: PagecallWebView, error: Error) {
        DispatchQueue.main.async {
            self.progressView.setProgress(0.25, animated: true)
        }
    }

    func pagecallDidLoad(_ view: PagecallWebView) {
        movePencil()
        self.progressView.setProgress(1, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            self.loadingView.isHidden = true
        }
    }

}
