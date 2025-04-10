import UIKit

struct PencilEvent {
    let location: CGPoint
    let phase: TouchPhase
    let timestamp: Date
}

class PencilDebugOverlay: UIView {
    private var events: [PencilEvent] = []
    private var isVisible = false
    private let clearButton = UIButton(type: .system)
    private let toggleButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        clearButton.setTitle("Clear", for: .normal)
        clearButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.7)
        clearButton.layer.cornerRadius = 8
        clearButton.addTarget(self, action: #selector(clearEvents), for: .touchUpInside)

        toggleButton.setTitle("Overlay", for: .normal)
        toggleButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.7)
        toggleButton.layer.cornerRadius = 8
        toggleButton.addTarget(self, action: #selector(toggleOverlay), for: .touchUpInside)

        // 버튼 위치 설정
        clearButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 100, width: 80, height: 40)
        toggleButton.frame = CGRect(x: 110, y: UIScreen.main.bounds.height - 100, width: 80, height: 40)

        // 버튼 추가
        addSubview(clearButton)
        addSubview(toggleButton)
    }

    func addEvent(locations: [CGPoint], phase: TouchPhase) {
        let now = Date()
        let newEvents = locations.map { location in
            return PencilEvent(location: location, phase: phase, timestamp: now)
        }
        events.append(contentsOf: newEvents)
        setNeedsDisplay()
    }

    @objc func clearEvents() {
        events.removeAll()
        setNeedsDisplay()
    }

    @objc func toggleOverlay() {
        isVisible = !isVisible
        backgroundColor = isVisible ? UIColor.white.withAlphaComponent(0.3) : .clear
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard isVisible, let context = UIGraphicsGetCurrentContext() else { return }

        for event in events {
            let color = switch event.phase {
            case .began: UIColor.blue
            case .moved: UIColor.gray
            case .ended: UIColor.green
            case .cancelled: UIColor.red
            }

            context.setStrokeColor(color.cgColor)
            context.setFillColor(color.withAlphaComponent(0.3).cgColor)
            context.setLineWidth(1.0)

            // 직경 5의 원 그리기
            let radius: CGFloat = 5.0
            let circlePath = UIBezierPath(arcCenter: event.location,
                                         radius: radius / 2,
                                         startAngle: 0,
                                         endAngle: CGFloat(2 * Double.pi),
                                         clockwise: true)

            context.addPath(circlePath.cgPath)
            context.drawPath(using: .fillStroke)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // 버튼을 터치한 경우 버튼 반환
        if view == clearButton || view == toggleButton {
            return view
        }
        return nil
    }
}
