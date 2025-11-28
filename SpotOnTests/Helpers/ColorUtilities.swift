//
//  ColorUtilities.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftUI
import XCTest
@testable import SpotOn

/// Comprehensive color utilities for avatar color testing and medical app theme validation
class ColorUtilities {

    // MARK: - Hex Color Validation

    /// Validates hex color format and returns normalized hex string
    /// - Parameter hex: Input hex color string
    /// - Returns: Validated and normalized hex color
    static func validateHexColor(_ hex: String) -> ColorValidationResult {
        let cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for empty string
        guard !cleanedHex.isEmpty else {
            return ColorValidationResult(
                isValid: false,
                normalizedHex: nil,
                rgb: nil,
                hsb: nil,
                issues: ["Hex color string is empty"]
            )
        }

        // Add # if missing
        let hexWithHash = cleanedHashSymbol(cleanedHex)

        // Validate format
        guard isValidHexFormat(hexWithHash) else {
            return ColorValidationResult(
                isValid: false,
                normalizedHex: nil,
                rgb: nil,
                hsb: nil,
                issues: ["Invalid hex color format. Expected format: #RRGGBB or #RGB"]
            )
        }

        // Convert to RGB
        guard let rgb = hexToRGB(hexWithHash) else {
            return ColorValidationResult(
                isValid: false,
                normalizedHex: nil,
                rgb: nil,
                hsb: nil,
                issues: ["Failed to convert hex to RGB values"]
            )
        }

        // Validate RGB range
        guard rgb.r >= 0 && rgb.r <= 255 && rgb.g >= 0 && rgb.g <= 255 && rgb.b >= 0 && rgb.b <= 255 else {
            return ColorValidationResult(
                isValid: false,
                normalizedHex: hexWithHash,
                rgb: rgb,
                hsb: nil,
                issues: ["RGB values out of valid range (0-255)"]
            )
        }

        // Convert to HSB
        let hsb = rgbToHSB(rgb)

        return ColorValidationResult(
            isValid: true,
            normalizedHex: hexWithHash,
            rgb: rgb,
            hsb: hsb,
            issues: []
        )
    }

    // MARK: - Medical Color Appropriateness

    /// Validates if color is appropriate for medical avatar use
    /// - Parameter hex: Hex color string
    /// - Returns: Medical color appropriateness result
    static func validateMedicalAvatarColor(_ hex: String) -> MedicalColorResult {
        let validationResult = validateHexColor(hex)

        guard validationResult.isValid else {
            return MedicalColorResult(
                isValid: false,
                isMedicallyAppropriate: false,
                accessibilityScore: 0,
                medicalIssues: validationResult.issues,
                accessibilityIssues: [],
                recommendations: ["Fix hex color format first"]
            )
        }

        var medicalIssues: [String] = []
        var accessibilityIssues: [String] = []
        var recommendations: [String] = []

        // Check medical appropriateness
        let rgb = validationResult.rgb!
        let hsb = validationResult.hsb!

        // Avoid colors that could be confused with medical indicators
        if isMedicalIndicatorColor(rgb) {
            medicalIssues.append("Color may be confused with medical indicator colors (red, yellow, green)")
            recommendations.append("Choose a color with distinct medical characteristics")
        }

        // Ensure sufficient saturation for visibility
        if hsb.saturation < 20 {
            medicalIssues.append("Color saturation too low for medical visibility")
            recommendations.append("Increase saturation for better visibility")
        }

        // Ensure reasonable brightness
        if hsb.brightness < 20 {
            medicalIssues.append("Color too dark for medical visibility")
            recommendations.append("Increase brightness for better visibility")
        }

        // Check accessibility
        let accessibilityScore = calculateAccessibilityScore(rgb)

        // Check contrast with white text (common in avatars)
        let whiteContrast = calculateContrastRatio(rgb, RGB(r: 255, g: 255, b: 255))
        if whiteContrast < 3.0 {
            accessibilityIssues.append("Insufficient contrast with white text (\(String(format: "%.2f", whiteContrast)):1)")
            recommendations.append("Increase contrast for better white text readability")
        }

        // Check contrast with black text
        let blackContrast = calculateContrastRatio(rgb, RGB(r: 0, g: 0, b: 0))
        if blackContrast < 3.0 {
            accessibilityIssues.append("Insufficient contrast with black text (\(String(format: "%.2f", blackContrast)):1)")
            recommendations.append("Increase contrast for better black text readability")
        }

        // Color blindness considerations
        let colorBlindnessIssues = checkColorBlindnessCompatibility(rgb)
        accessibilityIssues.append(contentsOf: colorBlindnessIssues)

        let isMedicallyAppropriate = medicalIssues.isEmpty
        let isAccessible = accessibilityIssues.isEmpty

        return MedicalColorResult(
            isValid: validationResult.isValid,
            isMedicallyAppropriate: isMedicallyAppropriate,
            accessibilityScore: accessibilityScore,
            medicalIssues: medicalIssues,
            accessibilityIssues: accessibilityIssues,
            recommendations: recommendations
        )
    }

    // MARK: - Color Palette Validation

    /// Validates a complete color palette for medical app
    /// - Parameter colors: Array of hex color strings
    /// - Returns: Color palette validation result
    static func validateMedicalColorPalette(_ colors: [String]) -> ColorPaletteResult {
        var colorResults: [MedicalColorResult] = []
        var paletteIssues: [String] = []
        var colorSimilarities: [ColorSimilarity] = []

        // Validate each color
        for color in colors {
            let result = validateMedicalAvatarColor(color)
            colorResults.append(result)
        }

        // Check for color similarity issues
        for i in 0..<colors.count {
            for j in (i+1)..<colors.count {
                let similarity = calculateColorSimilarity(colors[i], colors[j])
                if similarity.similarity > 0.8 { // 80% similarity threshold
                    colorSimilarities.append(similarity)
                }
            }
        }

        // Check palette diversity
        let uniqueHueRanges = calculateUniqueHueRanges(colorResults.compactMap { $0.rgb })
        if uniqueHueRanges.count < 3 {
            paletteIssues.append("Palette lacks sufficient color diversity")
        }

        // Check overall accessibility
        let accessibleColors = colorResults.filter { $0.accessibilityScore >= 70 }
        if accessibleColors.count < colors.count / 2 {
            paletteIssues.append("More than half the colors have accessibility issues")
        }

        // Check medical appropriateness
        let medicalColors = colorResults.filter { $0.isMedicallyAppropriate }
        if medicalColors.count < colors.count {
            paletteIssues.append("Some colors are not medically appropriate")
        }

        return ColorPaletteResult(
            colorResults: colorResults,
            colorSimilarities: colorSimilarities,
            paletteIssues: paletteIssues,
            uniqueHueRanges: uniqueHueRanges,
            overallValid: paletteIssues.isEmpty && colorSimilarities.isEmpty
        )
    }

    // MARK: - Color Generation for Testing

    /// Generates medically appropriate colors for testing
    /// - Parameter count: Number of colors to generate
    /// - Returns: Array of medically appropriate hex colors
    static func generateMedicalAvatarColors(count: Int) -> [String] {
        var colors: [String] = []
        let hueStep = 360.0 / Double(count)

        for i in 0..<count {
            let hue = Double(i) * hueStep
            let saturation = Double.random(in: 60...90) // Good saturation
            let brightness = Double.random(in: 70...90) // Good brightness

            let rgb = hsbToRGB(HSB(h: hue, s: saturation, b: brightness))
            let hex = rgbToHex(rgb)
            colors.append(hex)
        }

        return colors
    }

    /// Generates problematic colors for negative testing
    /// - Returns: Array of problematic hex colors
    static func generateProblematicColors() -> [String] {
        return [
            "#000000", // Too dark
            "#FFFFFF", // Too light
            "#FF0000", // Medical red
            "#FFFF00", // Medical yellow
            "#00FF00", // Medical green
            "#808080", // Too low saturation
            "#FF00FF", // Color blind problematic
            "#00FFFF", // Color blind problematic
            "#123456", // Too dark
            "#FEDCBA"  // Too light
        ]
    }

    // MARK: - Helper Methods

    private static func cleanedHashSymbol(_ hex: String) -> String {
        return hex.hasPrefix("#") ? hex : "#\(hex)"
    }

    private static func isValidHexFormat(_ hex: String) -> Bool {
        let pattern = "^#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$"
        return hex.range(of: pattern, options: .regularExpression) != nil
    }

    private static func hexToRGB(_ hex: String) -> RGB? {
        let cleanedHex = hex.replacingOccurrences(of: "#", with: "")

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0

        if cleanedHex.count == 6 {
            Scanner(string: cleanedHex.prefix(2)).scanHexInt64(&r)
            Scanner(string: cleanedHex.dropFirst(2).prefix(2)).scanHexInt64(&g)
            Scanner(string: cleanedHex.dropFirst(4).prefix(2)).scanHexInt64(&b)
        } else if cleanedHex.count == 3 {
            Scanner(string: String(cleanedHex.prefix(1))).scanHexInt64(&r)
            Scanner(string: String(cleanedHex.dropFirst(1).prefix(1))).scanHexInt64(&g)
            Scanner(string: String(cleanedHex.dropFirst(2).prefix(1))).scanHexInt64(&b)
            r = r * 17
            g = g * 17
            b = b * 17
        } else {
            return nil
        }

        return RGB(r: Int(r), g: Int(g), b: Int(b))
    }

    private static func rgbToHex(_ rgb: RGB) -> String {
        return String(format: "#%02X%02X%02X", rgb.r, rgb.g, rgb.b)
    }

    private static func rgbToHSB(_ rgb: RGB) -> HSB {
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        var hue: Double = 0
        let saturation = maxVal == 0 ? 0 : delta / maxVal
        let brightness = maxVal

        if delta != 0 {
            if maxVal == r {
                hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6) * 60
            } else if maxVal == g {
                hue = ((b - r) / delta + 2) * 60
            } else {
                hue = ((r - g) / delta + 4) * 60
            }
        }

        return HSB(h: hue < 0 ? hue + 360 : hue, s: saturation * 100, b: brightness * 100)
    }

    private static func hsbToRGB(_ hsb: HSB) -> RGB {
        let h = hsb.h / 360.0
        let s = hsb.s / 100.0
        let b = hsb.b / 100.0

        let c = b * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c

        var r: Double = 0, g: Double = 0, bl: Double = 0

        if h >= 0 && h < 1/6 {
            r = c; g = x; bl = 0
        } else if h >= 1/6 && h < 2/6 {
            r = x; g = c; bl = 0
        } else if h >= 2/6 && h < 3/6 {
            r = 0; g = c; bl = x
        } else if h >= 3/6 && h < 4/6 {
            r = 0; g = x; bl = c
        } else if h >= 4/6 && h < 5/6 {
            r = x; g = 0; bl = c
        } else if h >= 5/6 && h < 1 {
            r = c; g = 0; bl = x
        }

        return RGB(
            r: Int((r + m) * 255),
            g: Int((g + m) * 255),
            b: Int((bl + m) * 255)
        )
    }

    private static func calculateContrastRatio(_ rgb1: RGB, _ rgb2: RGB) -> Double {
        let l1 = calculateLuminance(rgb1)
        let l2 = calculateLuminance(rgb2)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func calculateLuminance(_ rgb: RGB) -> Double {
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0

        let rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
        let bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)

        return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear
    }

    private static func calculateAccessibilityScore(_ rgb: RGB) -> Int {
        let whiteContrast = calculateContrastRatio(rgb, RGB(r: 255, g: 255, b: 255))
        let blackContrast = calculateContrastRatio(rgb, RGB(r: 0, g: 0, b: 0))

        let maxContrast = max(whiteContrast, blackContrast)

        // Score based on WCAG standards
        if maxContrast >= 7 {
            return 100 // AAA
        } else if maxContrast >= 4.5 {
            return 80  // AA
        } else if maxContrast >= 3 {
            return 60  // Minimum for large text
        } else {
            return Int(maxContrast * 20) // Below minimum
        }
    }

    private static func isMedicalIndicatorColor(_ rgb: RGB) -> Bool {
        // Check if color is too close to medical indicator colors
        let red = RGB(r: 255, g: 0, b: 0)
        let yellow = RGB(r: 255, g: 255, b: 0)
        let green = RGB(r: 0, g: 255, b: 0)

        let redSimilarity = 1.0 - calculateColorDistance(rgb, red) / 441.67
        let yellowSimilarity = 1.0 - calculateColorDistance(rgb, yellow) / 441.67
        let greenSimilarity = 1.0 - calculateColorDistance(rgb, green) / 441.67

        return redSimilarity > 0.7 || yellowSimilarity > 0.7 || greenSimilarity > 0.7
    }

    private static func checkColorBlindnessCompatibility(_ rgb: RGB) -> [String] {
        var issues: [String] = []

        // Simulate different types of color blindness
        let protanopia = simulateProtanopia(rgb)
        let deuteranopia = simulateDeuteranopia(rgb)
        let tritanopia = simulateTritanopia(rgb)

        // Check if the color becomes indistinguishable from common colors
        let gray = RGB(r: 128, g: 128, b: 128)

        if calculateColorDistance(protanopia, gray) < 50 {
            issues.append("Color may be difficult to distinguish for people with protanopia")
        }

        if calculateColorDistance(deuteranopia, gray) < 50 {
            issues.append("Color may be difficult to distinguish for people with deuteranopia")
        }

        if calculateColorDistance(tritanopia, gray) < 50 {
            issues.append("Color may be difficult to distinguish for people with tritanopia")
        }

        return issues
    }

    private static func simulateProtanopia(_ rgb: RGB) -> RGB {
        // Simplified protanopia simulation (red-blind)
        return RGB(
            r: Int(0.567 * Double(rgb.r) + 0.433 * Double(rgb.g)),
            g: Int(0.558 * Double(rgb.r) + 0.442 * Double(rgb.g)),
            b: Int(0.242 * Double(rgb.g) + 0.758 * Double(rgb.b))
        )
    }

    private static func simulateDeuteranopia(_ rgb: RGB) -> RGB {
        // Simplified deuteranopia simulation (green-blind)
        return RGB(
            r: Int(0.625 * Double(rgb.r) + 0.375 * Double(rgb.g)),
            g: Int(0.7 * Double(rgb.r) + 0.3 * Double(rgb.g)),
            b: Int(0.3 * Double(rgb.g) + 0.7 * Double(rgb.b))
        )
    }

    private static func simulateTritanopia(_ rgb: RGB) -> RGB {
        // Simplified tritanopia simulation (blue-blind)
        return RGB(
            r: Int(0.95 * Double(rgb.r) + 0.05 * Double(rgb.g)),
            g: Int(0.433 * Double(rgb.g) + 0.567 * Double(rgb.b)),
            b: Int(0.475 * Double(rgb.g) + 0.525 * Double(rgb.b))
        )
    }

    private static func calculateColorDistance(_ rgb1: RGB, _ rgb2: RGB) -> Double {
        let dr = Double(rgb1.r - rgb2.r)
        let dg = Double(rgb1.g - rgb2.g)
        let db = Double(rgb1.b - rgb2.b)

        return sqrt(dr * dr + dg * dg + db * db)
    }

    private static func calculateColorSimilarity(_ hex1: String, _ hex2: String) -> ColorSimilarity {
        let result1 = validateHexColor(hex1)
        let result2 = validateHexColor(hex2)

        guard let rgb1 = result1.rgb, let rgb2 = result2.rgb else {
            return ColorSimilarity(color1: hex1, color2: hex2, similarity: 0, distance: 0)
        }

        let distance = calculateColorDistance(rgb1, rgb2)
        let maxDistance = sqrt(3 * 255 * 255) // Maximum possible distance
        let similarity = 1.0 - (distance / maxDistance)

        return ColorSimilarity(color1: hex1, color2: hex2, similarity: similarity, distance: distance)
    }

    private static func calculateUniqueHueRanges(_ rgbs: [RGB]) -> [String] {
        var hueRanges: [String] = []

        for rgb in rgbs {
            let hsb = rgbToHSB(rgb)
            let hueRange = getHueRange(hsb.h)
            if !hueRanges.contains(hueRange) {
                hueRanges.append(hueRange)
            }
        }

        return hueRanges
    }

    private static func getHueRange(_ hue: Double) -> String {
        switch hue {
        case 0..<30, 330..<360:
            return "Red"
        case 30..<60:
            return "Orange"
        case 60..<120:
            return "Yellow-Green"
        case 120..<180:
            return "Green-Cyan"
        case 180..<240:
            return "Blue"
        case 240..<300:
            return "Purple"
        case 300..<330:
            return "Pink"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Supporting Types

struct RGB {
    let r: Int
    let g: Int
    let b: Int
}

struct HSB {
    let h: Double
    let s: Double
    let b: Double
}

struct ColorValidationResult {
    let isValid: Bool
    let normalizedHex: String?
    let rgb: RGB?
    let hsb: HSB?
    let issues: [String]
}

struct MedicalColorResult {
    let isValid: Bool
    let isMedicallyAppropriate: Bool
    let accessibilityScore: Int
    let medicalIssues: [String]
    let accessibilityIssues: [String]
    let recommendations: [String]
}

struct ColorPaletteResult {
    let colorResults: [MedicalColorResult]
    let colorSimilarities: [ColorSimilarity]
    let paletteIssues: [String]
    let uniqueHueRanges: [String]
    let overallValid: Bool
}

struct ColorSimilarity {
    let color1: String
    let color2: String
    let similarity: Double
    let distance: Double
}

// MARK: - XCTest Extensions

extension XCTestCase {
    /// Asserts hex color is valid
    func assertValidHexColor(
        _ hex: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = ColorUtilities.validateHexColor(hex)
        XCTAssertTrue(
            result.isValid,
            "Hex color '\(hex)' is not valid: \(result.issues.joined(separator: ", "))",
            file: file,
            line: line
        )
    }

    /// Asserts color is medically appropriate
    func assertMedicallyAppropriateColor(
        _ hex: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = ColorUtilities.validateMedicalAvatarColor(hex)
        XCTAssertTrue(
            result.isMedicallyAppropriate,
            "Color '\(hex)' is not medically appropriate: \(result.medicalIssues.joined(separator: ", "))",
            file: file,
            line: line
        )
    }

    /// Asserts color meets accessibility standards
    func assertAccessibleColor(
        _ hex: String,
        minimumScore: Int = 70,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = ColorUtilities.validateMedicalAvatarColor(hex)
        XCTAssertGreaterThanOrEqual(
            result.accessibilityScore,
            minimumScore,
            "Color '\(hex)' accessibility score \(result.accessibilityScore) is below minimum \(minimumScore): \(result.accessibilityIssues.joined(separator: ", "))",
            file: file,
            line: line
        )
    }

    /// Asserts color palette is diverse and valid
    func assertValidColorPalette(
        _ colors: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = ColorUtilities.validateMedicalColorPalette(colors)
        XCTAssertTrue(
            result.overallValid,
            "Color palette has issues: \(result.paletteIssues.joined(separator: ", "))",
            file: file,
            line: line
        )
    }
}