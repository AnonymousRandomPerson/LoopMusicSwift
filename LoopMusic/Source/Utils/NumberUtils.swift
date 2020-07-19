class NumberUtils {
    
    /// Formats a decimal number into a string.
    /// - parameter number: number to format.
    /// - returns: Number formatted as a string.
    static func formatNumber(_ number: Double) -> String {
        /// Number format object to format the number with.
        let numberFormat = NumberFormatter()
        numberFormat.minimumFractionDigits = 0
        numberFormat.maximumFractionDigits = 5
        return numberFormat.string(from: NSNumber(value: number))!
    }
}
