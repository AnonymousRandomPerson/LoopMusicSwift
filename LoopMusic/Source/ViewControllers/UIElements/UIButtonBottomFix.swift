import UIKit

/// UIButton with a bunch of hacky workarounds for the bug where buttons aren't highlighted when pressed near the bottom of the screen. https://stackoverflow.com/questions/23046539/uibutton-fails-to-properly-register-touch-in-bottom-region-of-iphone-screen/
class UIButtonBottomFix: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerResignActiveObserver()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerResignActiveObserver()
    }
    
    /// Force the button to unhighlight whenever the app becomes inactive. This usually prevents the button from getting stuck highlighted when completing a swipe up gesture to open the Control Center.
    private func registerResignActiveObserver() {
        // Force the button to unhighlight whenever the app becomes inactive. Thi
        NotificationCenter.default.addObserver(self, selector: #selector(forceUnhighlighted), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc func forceUnhighlighted() {
        isHighlighted = false
    }
    
    /// Checks if a segue is happening.
    private var controllerIsTransitioning: Bool {
        // Get the parent view controller by walking up the view hierarchy. https://stackoverflow.com/questions/1372977/given-a-view-how-do-i-get-its-viewcontroller
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                // Now check if the view controller has an active transitioning coordinator.
                return viewController.transitionCoordinator != nil
            }
        }
        return false
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let inside = super.point(inside: point, with: event)
        // Force the highlight state to match the touch+inside state. But only if:
        // 1. The app is active. This prevents the case where the button is touched after a willResignActiveNotification but before it actually goes off screen.
        // 2. A segue isn't currently happening. This prevents the case where you can press the button during a segue animation, and the button gets stuck highlighted without the button's event actually triggering.
        if UIApplication.shared.applicationState == .active && event?.type == .touches && inside != isHighlighted && !controllerIsTransitioning {
            isHighlighted = inside
        }
        return inside
    }
}
