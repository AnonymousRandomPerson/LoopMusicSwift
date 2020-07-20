import UIKit

/// Utility functions for font modification. https://stackoverflow.com/questions/38533323/ios-swift-making-font-toggle-bold-italic-bolditalic-normal-without-change-oth
class FontUtils {
    /// Checks if a font is bold.
    /// - parameter font: The font to check.
    static func isBold(_ font: UIFont) -> Bool {
        return font.fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    /// Applies the bold trait to a font.
    /// - parameter font: The font to bold.
    static func boldFont(_ font: UIFont) -> UIFont {
        if isBold(font) {
            return font
        }
        return UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: font.pointSize)
    }

    /// Removes the bold trait from a font.
    /// - parameter font: The font to unbold.
    static func unboldFont(_ font: UIFont) -> UIFont {
        if !isBold(font) {
            return font
        }
        var symTraits = font.fontDescriptor.symbolicTraits
        symTraits.remove([.traitBold])
        return UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(symTraits)!, size: font.pointSize)
    }
}
