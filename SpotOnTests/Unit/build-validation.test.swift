import XCTest
@testable import SpotOn

final class BuildValidationTest: XCTestCase {

    func testAppBuildsWithIOS17DeploymentTarget() throws {
        // This test validates that the app can build successfully with iOS 17.0 deployment target
        // The test should initially FAIL due to deployment target mismatch (iOS 26.1)

        // Get the build settings
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

        // Extract deployment target from build settings
        let lines = output.components(separatedBy: .newlines)
        var deploymentTarget: String?

        for line in lines {
            if line.contains("IPHONEOS_DEPLOYMENT_TARGET") && !line.contains("RECOMMENDED") {
                deploymentTarget = line.components(separatedBy: " = ").last
                break
            }
        }

        // RED PHASE: This should FAIL initially because target is 26.1
        XCTAssertEqual(deploymentTarget, "17.0", "Deployment target should be iOS 17.0 for iPhone 13 compatibility")
    }

    func testAppCanBuildForIOS17Device() throws {
        // Test that the app can build for iOS 17+ devices
        // This validates build compatibility with iPhone 13 (iOS 18.6.2)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = [
            "-scheme", "SpotOn",
            "-destination", "platform=iOS Simulator,name=iPhone 17,OS=17.0",
            "build"
        ]

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        // RED PHASE: Should fail with iOS 26.1 deployment target
        XCTAssertEqual(process.terminationStatus, 0, "Build should succeed for iOS 17.0 deployment target")
    }
}