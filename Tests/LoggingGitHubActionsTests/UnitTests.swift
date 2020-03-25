import XCTest
import Foundation
@testable import Logging
@testable import LoggingGitHubActions

final class UnitTests: XCTestCase {
    func testBootstrap() {
        Logging.LoggingSystem.bootstrap(GitHubActionsLogHandler.standardOutput(label:))
        XCTAssertTrue(Logger(label: #file).handler is GitHubActionsLogHandler)
    }

    func testTrace() {
        var logLevel: Logger.Level?
        let expectation = MockTextOutputStream { logger in
            logLevel = logger.handler.logLevel
            logger.trace("🥱")
        }

        XCTAssertGreaterThan(logLevel!, .trace)
        XCTAssertEqual(expectation.lines.count, 0)
    }

    func testDebug() {
        let expectation = MockTextOutputStream { logger in
            logger.debug("😐")
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::debug "))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::😐"))
    }

    func testInfo() {
        let expectation = MockTextOutputStream { logger in
            logger.info("🤔")
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::debug "))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::🤔"))
    }

    func testNotice() {
        let expectation = MockTextOutputStream { logger in
            logger.notice("😳")
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::debug "))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::😳"))
    }

    func testWarning() {
        let expectation = MockTextOutputStream { logger in
            logger.warning("😰")
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::warning "))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::😰"))
    }

    func testError() {
        let expectation = MockTextOutputStream { logger in
            logger.error("😱")
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::error "))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::😱"))
    }

    func testCritical() {
        let expectation = MockTextOutputStream { logger in
            logger.critical("😵")
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::error "))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::😵"))
    }

    func testLogWithMetadata() {
        let expectation = MockTextOutputStream { logger in
            logger.debug("Results", metadata: ["🥇": "🐶", "🥈": "🐱", "🥉": "🐠"])
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertTrue(expectation.lines[0].hasPrefix("::debug "))
        XCTAssertTrue(expectation.lines[0].contains("🥇=🐶"))
        XCTAssertTrue(expectation.lines[0].contains("🥈=🐱"))
        XCTAssertTrue(expectation.lines[0].contains("🥉=🐠"))
        XCTAssertTrue(expectation.lines[0].hasSuffix("::Results"))
    }

    func testMaskValue() {
        let password = "Sw0rdf1sh"
        let expectation = MockTextOutputStream { logger in
            let handler = logger.handler as! GitHubActionsLogHandler
            handler.mask(value: password)
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertEqual(expectation.lines[0], "::add-mask::\(password)")
    }

    func testSetEnvironmentVariable() {
        let name = "SPLINE_RETICULATION_CONSTANT", value = "42"
        let expectation = MockTextOutputStream { logger in
            let handler = logger.handler as! GitHubActionsLogHandler
            handler.setEnvironmentVariable(name: name, value: value)
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertEqual(expectation.lines[0], "::set-env name=\(name)::\(value)")
    }

    func testSetOutputParameter() {
        let name = "success", value = "true"
        let expectation = MockTextOutputStream { logger in
            let handler = logger.handler as! GitHubActionsLogHandler
            handler.setOutputParameter(name: name, value: value)
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertEqual(expectation.lines[0], "::set-output name=\(name)::\(value)")
    }

    func testAddSystemPath() {
        let path = "/usr/local/bin"
        let expectation = MockTextOutputStream { logger in
            let handler = logger.handler as! GitHubActionsLogHandler
            handler.addSystemPath(path)
        }

        XCTAssertEqual(expectation.lines.count, 1)
        XCTAssertEqual(expectation.lines[0], "::add-path::\(path)")
    }

    func testStopStartWorkflowCommands() throws {
        let expectation = MockTextOutputStream { logger in
            let handler = logger.handler as! GitHubActionsLogHandler
            handler.withoutProcessingWorkflowCommands {
                logger.debug("Entered octocatAddition method")
                logger.warning("Missing semicolon")
                logger.error("Something went wrong")
            }
        }

        XCTAssertEqual(expectation.lines.count, 5)

        let pattern = #"::stop-commands::(.+)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let firstLine = expectation.lines[0]
        let match = regex.firstMatch(in: firstLine, options: [], range: NSRange(firstLine.startIndex..<firstLine.endIndex, in: firstLine))!
        let range = Range(match.range(at: 1), in: firstLine)!
        let token = firstLine[range]

        XCTAssertEqual(expectation.lines[0], "::stop-commands::\(token)")
        XCTAssertEqual(expectation.lines[4], "::\(token)::")
    }
}
