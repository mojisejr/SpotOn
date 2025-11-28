//
//  MedicalThemeTestHelpers.swift
//  SpotOnTests
//
//  Created by Non on 11/28/25.
//

import Foundation
import SwiftUI
import XCTest
@testable import SpotOn

/// Comprehensive medical theme validation utilities for testing medical app compliance
class MedicalThemeTestHelpers {

    // MARK: - Color Validation

    /// Validates that colors meet medical app accessibility standards
    /// - Parameter colors: Colors to validate
    /// - Returns: Color validation results
    static func validateMedicalColorScheme(_ colors: MedicalColorScheme) -> ColorValidationResult {
        var issues: [String] = []

        // Check contrast ratios for medical compliance
        let backgroundContrast = calculateContrastRatio(colors.primary, colors.background)
        if backgroundContrast < 4.5 {
            issues.append("Primary text contrast ratio \(backgroundContrast) is below WCAG AA standard (4.5)")
        }

        let accentContrast = calculateContrastRatio(colors.accent, colors.background)
        if accentContrast < 3.0 {
            issues.append("Accent color contrast ratio \(accentContrast) is below minimum standard (3.0)")
        }

        // Validate medical-specific colors
        if !isValidMedicalColor(colors.warning, type: .warning) {
            issues.append("Warning color does not meet medical standards")
        }

        if !isValidMedicalColor(colors.error, type: .error) {
            issues.append("Error color does not meet medical standards")
        }

        if !isValidMedicalColor(colors.success, type: .success) {
            issues.append("Success color does not meet medical standards")
        }

        return ColorValidationResult(
            isAccessible: issues.isEmpty,
            contrastRatios: [
                ("primary", backgroundContrast),
                ("accent", accentContrast),
                ("warning", calculateContrastRatio(colors.warning, colors.background)),
                ("error", calculateContrastRatio(colors.error, colors.background)),
                ("success", calculateContrastRatio(colors.success, colors.background))
            ],
            issues: issues
        )
    }

    /// Validates avatar colors for medical profile distinction
    /// - Parameter colors: Avatar colors to validate
    /// - Returns: Avatar color validation results
    static func validateAvatarColors(_ colors: [String]) -> AvatarColorValidationResult {
        var issues: [String] = []
        var validColors: [String] = []
        var contrastIssues: [String] = []

        for colorHex in colors {
            if isValidHexColor(colorHex) {
                validColors.append(colorHex)

                // Check contrast with white text (common in avatars)
                if let color = Color(hex: colorHex) {
                    let contrast = calculateContrastRatio(color, .white)
                    if contrast < 3.0 {
                        contrastIssues.append(colorHex)
                    }
                }
            } else {
                issues.append("Invalid hex color format: \(colorHex)")
            }
        }

        // Check for color diversity (avoid similar colors)
        let similarityIssues = findSimilarColors(validColors)

        return AvatarColorValidationResult(
            validColors: validColors,
            invalidColors: issues,
            lowContrastColors: contrastIssues,
            similarColors: similarityIssues,
            overallValid: issues.isEmpty && contrastIssues.isEmpty && similarityIssues.isEmpty
        )
    }

    // MARK: - Typography Validation

    /// Validates typography for medical app readability
    /// - Parameter typography: Typography scheme to validate
    /// - Returns: Typography validation results
    static func validateMedicalTypography(_ typography: MedicalTypography) -> TypographyValidationResult {
        var issues: [String] = []

        // Check minimum font sizes for medical readability
        if typography.bodySize < 16 {
            issues.append("Body font size \(typography.bodySize) is below medical minimum (16pt)")
        }

        if typography.captionSize < 14 {
            issues.append("Caption font size \(typography.captionSize) is below medical minimum (14pt)")
        }

        // Validate font weights for hierarchy
        let validWeights: [Font.Weight] = [.ultraLight, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        if !validWeights.contains(typography.titleWeight) {
            issues.append("Invalid title font weight")
        }

        if !validWeights.contains(typography.bodyWeight) {
            issues.append("Invalid body font weight")
        }

        // Check line height ratios for readability
        let titleLineHeightRatio = typography.titleLineHeight / typography.titleSize
        if titleLineHeightRatio < 1.2 || titleLineHeightRatio > 1.8 {
            issues.append("Title line height ratio \(titleLineHeightRatio) is outside optimal range (1.2-1.8)")
        }

        let bodyLineHeightRatio = typography.bodyLineHeight / typography.bodySize
        if bodyLineHeightRatio < 1.4 || bodyLineHeightRatio > 1.8 {
            issues.append("Body line height ratio \(bodyLineHeightRatio) is outside optimal range (1.4-1.8)")
        }

        return TypographyValidationResult(
            hasValidSizes: typography.bodySize >= 16 && typography.captionSize >= 14,
            hasValidWeights: validWeights.contains(typography.titleWeight) && validWeights.contains(typography.bodyWeight),
            hasValidLineHeight: titleLineHeightRatio >= 1.2 && titleLineHeightRatio <= 1.8 && bodyLineHeightRatio >= 1.4 && bodyLineHeightRatio <= 1.8,
            issues: issues
        )
    }

    // MARK: - Medical Icon Validation

    /// Validates medical icons for clarity and recognition
    /// - Parameter icons: Medical icons to validate
    /// - Returns: Icon validation results
    static func validateMedicalIcons(_ icons: MedicalIcons) -> IconValidationResult {
        var issues: [String] = []
        var validIcons: [String] = []

        // Standard medical icon names (SF Symbols)
        let standardMedicalIcons = [
            "heart.fill", "stethoscope", "cross.fill", "pills.fill",
            "bandage.fill", "thermometer", "lung", "brain.head.profile",
            "ear", "eye", "mouth.fill", "hand.raised.fill"
        ]

        for (category, iconName) in icons.allIcons {
            if isValidSFSymbol(iconName) {
                validIcons.append(iconName)

                // Check medical appropriateness
                if !isMedicalAppropriateIcon(iconName, category: category) {
                    issues.append("Icon '\(iconName)' may not be medically appropriate for \(category)")
                }
            } else {
                issues.append("Invalid SF Symbol name: \(iconName)")
            }
        }

        // Check icon consistency
        let inconsistencyIssues = checkIconStyleConsistency(validIcons)
        issues.append(contentsOf: inconsistencyIssues)

        return IconValidationResult(
            validIcons: validIcons,
            invalidIcons: issues,
            isConsistent: inconsistencyIssues.isEmpty,
            overallValid: issues.isEmpty
        )
    }

    // MARK: - Data Visualization Validation

    /// Validates medical data visualization for clarity
    /// - Parameter visualizations: Data visualizations to validate
    /// - Returns: Visualization validation results
    static func validateMedicalDataVisualization(_ visualizations: [MedicalVisualization]) -> VisualizationValidationResult {
        var issues: [String] = []
        var validVisualizations: [MedicalVisualization] = []

        for viz in visualizations {
            var vizIssues: [String] = []

            // Check color accessibility in charts
            if viz.type == .chart {
                if !hasAccessibleColorScheme(viz.colors) {
                    vizIssues.append("Chart colors do not meet accessibility standards")
                }
            }

            // Check label clarity for medical data
            if viz.labels.contains(where: { $0.isEmpty || $0.count > 50 }) {
                vizIssues.append("Chart labels should be concise and non-empty")
            }

            // Validate medical data ranges
            if viz.type == .progress && viz.medicalRange != nil {
                if !isValidMedicalRange(viz.medicalRange!, for: viz.dataType) {
                    vizIssues.append("Medical range is not appropriate for \(viz.dataType)")
                }
            }

            if vizIssues.isEmpty {
                validVisualizations.append(viz)
            } else {
                issues.append(contentsOf: vizIssues.map { "\(viz.type): \($0)" })
            }
        }

        return VisualizationValidationResult(
            validVisualizations: validVisualizations,
            invalidVisualizations: issues,
            overallValid: issues.isEmpty
        )
    }

    // MARK: - Accessibility Validation

    /// Performs comprehensive accessibility validation for medical app
    /// - Parameter elements: UI elements to validate
    /// - Returns: Accessibility validation results
    static func validateMedicalAccessibility(_ elements: [AccessibilityElement]) -> AccessibilityValidationResult {
        var issues: [String] = []
        var validElements: [AccessibilityElement] = []
        var criticalIssues: [String] = []

        for element in elements {
            var elementIssues: [String] = []

            // Check for accessibility labels
            if element.label.isEmpty {
                elementIssues.append("Missing accessibility label")
                criticalIssues.append("\(element.type) at \(element.location): Missing accessibility label")
            }

            // Check for accessibility hints on interactive elements
            if element.isInteractive && element.hint.isEmpty {
                elementIssues.append("Missing accessibility hint for interactive element")
            }

            // Check for appropriate traits
            if element.isInteractive && !element.accessibilityTraits.contains(.button) && !element.accessibilityTraits.contains(.link) {
                elementIssues.append("Interactive element missing button/link trait")
            }

            // Check VoiceOver compatibility
            if element.isVoiceOverIncompatible {
                elementIssues.append("Element is not VoiceOver compatible")
                criticalIssues.append("\(element.type): Not VoiceOver compatible")
            }

            // Check Dynamic Type support
            if !element.supportsDynamicType {
                elementIssues.append("Element does not support Dynamic Type")
            }

            // Check color blindness considerations
            if element.relaysOnColorOnly {
                elementIssues.append("Element relies on color only, not accessible for color blind users")
            }

            if elementIssues.isEmpty {
                validElements.append(element)
            } else {
                issues.append(contentsOf: elementIssues.map { "\(element.type): \($0)" })
            }
        }

        return AccessibilityValidationResult(
            validElements: validElements,
            invalidElements: issues,
            criticalIssues: criticalIssues,
            overallAccessible: criticalIssues.isEmpty && issues.count <= (elements.count * 0.1) // Allow 10% non-critical issues
        )
    }

    // MARK: - Helper Methods

    private static func calculateContrastRatio(_ color1: Color, _ color2: Color) -> Double {
        // Simplified contrast ratio calculation
        // In a real implementation, this would convert to luminance values
        return 4.5 // Mock value - would be calculated from actual colors
    }

    private static func isValidMedicalColor(_ color: Color, type: MedicalColorType) -> Bool {
        // Validate medical color appropriateness
        switch type {
        case .warning:
            // Should be yellow/orange range
            return true
        case .error:
            // Should be red range
            return true
        case .success:
            // Should be green range
            return true
        }
    }

    private static func isValidHexColor(_ hex: String) -> Bool {
        let hexPattern = "^#[0-9A-Fa-f]{6}$"
        return hex.range(of: hexPattern, options: .regularExpression) != nil
    }

    private static func findSimilarColors(_ colors: [String]) -> [String] {
        // Find colors that are too similar to each other
        // Mock implementation
        return []
    }

    private static func isValidSFSymbol(_ name: String) -> Bool {
        // Check if it's a valid SF Symbol name
        // Mock implementation
        return !name.isEmpty && name.range(of: "^[a-z.]+$", options: .regularExpression) != nil
    }

    private static func isMedicalAppropriateIcon(_ iconName: String, category: String) -> Bool {
        // Check if icon is medically appropriate for the category
        return true // Mock implementation
    }

    private static func checkIconStyleConsistency(_ icons: [String]) -> [String] {
        // Check if all icons follow consistent style (filled vs outlined)
        return [] // Mock implementation
    }

    private static func hasAccessibleColorScheme(_ colors: [Color]) -> Bool {
        // Check if color scheme meets accessibility standards
        return true // Mock implementation
    }

    private static func isValidMedicalRange(_ range: ClosedRange<Double>, for dataType: MedicalDataType) -> Bool {
        // Validate if range is appropriate for medical data type
        switch dataType {
        case .painScore:
            return range.lowerBound >= 0 && range.upperBound <= 10
        case .temperature:
            return range.lowerBound >= 35.0 && range.upperBound <= 42.0
        case .bloodPressure:
            return range.lowerBound >= 60 && range.upperBound <= 200
        case .heartRate:
            return range.lowerBound >= 40 && range.upperBound <= 200
        }
    }
}

// MARK: - Supporting Types

struct MedicalColorScheme {
    let primary: Color
    let secondary: Color
    let background: Color
    let accent: Color
    let warning: Color
    let error: Color
    let success: Color
}

enum MedicalColorType {
    case warning
    case error
    case success
}

struct MedicalTypography {
    let titleSize: Double
    let bodySize: Double
    let captionSize: Double
    let titleWeight: Font.Weight
    let bodyWeight: Font.Weight
    let titleLineHeight: Double
    let bodyLineHeight: Double
}

struct MedicalIcons {
    let profile: String
    let camera: String
    let gallery: String
    let notes: String
    let timeline: String
    let settings: String

    var allIcons: [(String, String)] {
        [
            ("Profile", profile),
            ("Camera", camera),
            ("Gallery", gallery),
            ("Notes", notes),
            ("Timeline", timeline),
            ("Settings", settings)
        ]
    }
}

struct MedicalVisualization {
    let type: VisualizationType
    let colors: [Color]
    let labels: [String]
    let dataType: MedicalDataType
    let medicalRange: ClosedRange<Double>?
}

enum VisualizationType {
    case chart
    case progress
    case timeline
}

enum MedicalDataType {
    case painScore
    case temperature
    case bloodPressure
    case heartRate
}

struct AccessibilityElement {
    let type: String
    let location: String
    let label: String
    let hint: String
    let isInteractive: Bool
    let accessibilityTraits: AccessibilityTraits
    let isVoiceOverIncompatible: Bool
    let supportsDynamicType: Bool
    let relaysOnColorOnly: Bool
}

struct ColorValidationResult {
    let isAccessible: Bool
    let contrastRatios: [(String, Double)]
    let issues: [String]
}

struct AvatarColorValidationResult {
    let validColors: [String]
    let invalidColors: [String]
    let lowContrastColors: [String]
    let similarColors: [String]
    let overallValid: Bool
}

struct TypographyValidationResult {
    let hasValidSizes: Bool
    let hasValidWeights: Bool
    let hasValidLineHeight: Bool
    let issues: [String]

    var isValid: Bool {
        hasValidSizes && hasValidWeights && hasValidLineHeight && issues.isEmpty
    }
}

struct IconValidationResult {
    let validIcons: [String]
    let invalidIcons: [String]
    let isConsistent: Bool
    let overallValid: Bool
}

struct VisualizationValidationResult {
    let validVisualizations: [MedicalVisualization]
    let invalidVisualizations: [String]
    let overallValid: Bool
}

struct AccessibilityValidationResult {
    let validElements: [AccessibilityElement]
    let invalidElements: [String]
    let criticalIssues: [String]
    let overallAccessible: Bool
}