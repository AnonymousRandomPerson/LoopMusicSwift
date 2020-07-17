import UIKit

/// UIButton whose background color lightens when highlighted.
class BackgroundHighlightedButton: UIButton {
    /// The ratio with which to mix white with the normal background color when highlighted.
    var lightening: Double = 0.25 {
        /// Clamp between 0 and 1.
        didSet {
            lightening = max(0, min(1, lightening))
        }
    }
    /// Cache of the button's normal background color.
    private var normalBackgroundColor: UIColor?
    /// The button's highlighted background color.
    private var highlightedBackgroundColor: UIColor? {
        get {
            if let color = normalBackgroundColor {
                // Mix the color with white (don't touch alpha).
                var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                return UIColor(red: lightenComponent(r), green: lightenComponent(g), blue: lightenComponent(b), alpha: a)
            }
            return nil
        }
    }

    /// Lighten a color component.
    private func lightenComponent(_ component: CGFloat) -> CGFloat {
        return CGFloat((1 - lightening) * Double(component) + lightening)
    }

    override open var isHighlighted: Bool {
        willSet {
            if normalBackgroundColor == nil && !isHighlighted {
                // Store the normal background color.
                normalBackgroundColor = backgroundColor
            }
        }
        didSet {
            if normalBackgroundColor != nil {
                if isHighlighted {
                    // Set the background color to highlighted.
                    backgroundColor = highlightedBackgroundColor
                } else {
                    // Set the background color to normal.
                    backgroundColor = normalBackgroundColor
                }
            }
        }
    }
}
