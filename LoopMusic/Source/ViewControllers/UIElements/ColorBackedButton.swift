import UIKit

/// UIButton whose background color lightens when highlighted and grays out when disabled.
class ColorBackedButton: UIButtonBottomFix {
    /// The ratio with which to mix white with the normal background color when highlighted.
    var highlightedLightening: Double = 0.25 {
        /// Clamp between 0 and 1.
        didSet {
            highlightedLightening = max(0, min(1, highlightedLightening))
        }
    }
    /// The ratio with which to mix gray with the normal background color when disabled.
    var disabledGrayness: Double = 0.2 {
        /// Clamp between 0 and 1.
        didSet {
            disabledGrayness = max(0, min(1, disabledGrayness))
        }
    }
    /// The fraction of the normal alpha when disabled.
    var disabledTransparency: Double = 0.4 {
        /// Clamp between 0 and 1.
        didSet {
            disabledTransparency = max(0, min(1, disabledTransparency))
        }
    }

    /// Cache of the button's normal background color.
    private var normalBackgroundColor: UIColor?
    /// The button's highlighted background color.
    private var highlightedBackgroundColor: UIColor? {
        if let color = normalBackgroundColor {
            // Mix the color with white (don't touch alpha).
            return mixColors(color, with: UIColor.white, ratio: highlightedLightening)
        }
        return nil
    }
    /// The button's disabled background color.
    private var disabledBackgroundColor: UIColor? {
        if let color = normalBackgroundColor {
            // Mix the color with gray (don't touch alpha).
            return mixColors(color, with: UIColor.gray, ratio: disabledGrayness)
        }
        return nil
    }

    /// Mix two colors with some ratio (but keeping the alpha value of the original color).
    private func mixColors(_ oldColor: UIColor, with newColor: UIColor, ratio: Double) -> UIColor {
        var (r0, g0, b0, a0) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        var (r1, g1, b1) = (CGFloat(0), CGFloat(0), CGFloat(0))
        oldColor.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
        newColor.getRed(&r1, green: &g1, blue: &b1, alpha: nil)
        return UIColor(red: mixComponents(r0, with: r1, ratio: ratio), green: mixComponents(g0, with: g1, ratio: ratio), blue: mixComponents(b0, with: b1, ratio: ratio), alpha: a0)
    }
    /// Mix in a new color component with an original color component, with some ratio.
    private func mixComponents(_ oldComponent: CGFloat, with newComponent: CGFloat, ratio: Double) -> CGFloat {
        return CGFloat((1-ratio) * Double(oldComponent) + ratio * Double(newComponent))
    }

    /// Cache of the button's normal alpha.
    private var normalAlpha: CGFloat?
    /// The button's disabled alpha.
    private var disabledAlpha: CGFloat? {
        if let a = normalAlpha {
            return CGFloat((1-disabledTransparency) * Double(a))
        }
        return nil
    }

    /// If needed, try to cache the normal background color and alpha.
    private func cacheColorsIfNormal() {
        if normalBackgroundColor == nil && !isHighlighted && isEnabled {
            // Store the normal background color and alpha.
            normalBackgroundColor = backgroundColor
            normalAlpha = alpha
        }
    }

    override open var isHighlighted: Bool {
        willSet {
            cacheColorsIfNormal()
        }
        didSet {
            if normalBackgroundColor != nil {
                if isHighlighted {
                    backgroundColor = highlightedBackgroundColor
                } else {
                    backgroundColor = normalBackgroundColor
                }
            }
        }
    }

    override open var isEnabled: Bool {
        willSet {
            cacheColorsIfNormal()
        }
        didSet {
            // Set the background color.
            if normalBackgroundColor != nil {
                if isEnabled {
                    backgroundColor = normalBackgroundColor
                } else {
                    backgroundColor = disabledBackgroundColor
                }
            }
            // Set the alpha.
            if normalAlpha != nil {
                if isEnabled {
                    alpha = normalAlpha!
                } else {
                    alpha = disabledAlpha!
                }
            }
        }
    }
}
