import XCTest
@testable import SpotOn

final class DeviceCompatibilityTest: XCTestCase {

    func testIPhone13CompatibilityWithDeploymentTarget() throws {
        // Test that iPhone 13 (iOS 18.6.2) is compatible with deployment target
        // iPhone 13 supports iOS 15.0+, so iOS 17.0 should be compatible

        // Check current deployment target
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = [
            "-showBuildSettings",
            "-scheme", "SpotOn"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // Extract deployment target
        let lines = output.components(separatedBy: .newlines)
        var deploymentTarget: String?

        for line in lines {
            if line.contains("IPHONEOS_DEPLOYMENT_TARGET") && !line.contains("RECOMMENDED") {
                deploymentTarget = line.components(separatedBy: " = ").last
                break
            }
        }

        // Convert to comparable version
        if let target = deploymentTarget {
            let targetVersion = Double(target) ?? 0.0
            let iPhone13MinVersion = 15.0  // iPhone 13 minimum iOS version

            // RED PHASE: Should FAIL initially because 26.1 > 18.6.2
            XCTAssertLessThanOrEqual(targetVersion, iPhone13MinVersion, "Deployment target should be compatible with iPhone 13")
        } else {
            XCTFail("Deployment target not found")
        }
    }

    func testDeploymentTargetMeetsProjectRequirements() throws {
        // Test that deployment target meets project's minimum requirement (iOS 17.0)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = [
            "-showBuildSettings",
            "-scheme", "SpotOn"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // Extract deployment target
        let lines = output.components(separatedBy: .newlines)
        var deploymentTarget: String?

        for line in lines {
            if line.contains("IPHONEOS_DEPLOYMENT_TARGET") && !line.contains("RECOMMENDED") {
                deploymentTarget = line.components(separatedBy: " = ").last
                break
            }
        }

        // Project requirement: iOS 17.0 minimum
        let projectMinimum = "17.0"

        // RED PHASE: Should FAIL because target is 26.1 instead of 17.0
        XCTAssertEqual(deploymentTarget, projectMinimum, "Deployment target should match project minimum requirement")
    }
}