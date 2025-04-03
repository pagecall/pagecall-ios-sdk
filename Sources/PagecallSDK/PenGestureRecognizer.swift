import UIKit

enum TouchPhase: String {
    case began = "began"
    case moved = "moved"
    case ended = "ended"
    case cancelled = "cancelled"
}

protocol PenGestureRecognizerDelegate: AnyObject {
    func didTouchesChange(_ touches: [UITouch], phase: TouchPhase)
}

class PenGestureRecognizer: UIGestureRecognizer {
    weak var eventDelegate: PenGestureRecognizerDelegate?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        allowedTouchTypes = [NSNumber(integerLiteral: UITouch.TouchType.pencil.rawValue)]
        allowedPressTypes = []
    }

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
        // Some gesture recognizers are waiting for this one to fail.
        // To avoid blocking other gestures, we intentionally set the state to `.failed`.
        state = .failed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        eventDelegate?.didTouchesChange(Array(touches), phase: .cancelled)
        state = .failed
    }
}
