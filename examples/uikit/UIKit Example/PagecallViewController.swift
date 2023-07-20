//
//  PagecallViewController.swift
//  UIKit Example
//
//  Created by 최성혁 on 2023/07/20.
//

import Foundation
import UIKit

enum Mode {
    case meet, replay
}

class PagecallViewController: UIViewController {
    init(roomId: String, accessToken: String, mode: Mode) {
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
