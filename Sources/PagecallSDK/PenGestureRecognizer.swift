

import UIKit

enum TouchPhase: Int {
    case began = 0
    case moved = 1
    case ended = 2
    case cancelled = 3
}

protocol PenGestureRecognizerDelegate: AnyObject {
    func didTouchesChange(_ touches: [UITouch], phase: TouchPhase)
}

class PenGestureRecognizer: UIGestureRecognizer {
    weak var eventDelegate: PenGestureRecognizerDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        eventDelegate?.didTouchesChange(Array(touches), phase: .began)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        eventDelegate?.didTouchesChange(Array(touches), phase: .moved)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        eventDelegate?.didTouchesChange(Array(touches), phase: .ended)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        eventDelegate?.didTouchesChange(Array(touches), phase: .cancelled)
    }
} 
