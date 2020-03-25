import XCTest
@testable import Logging
@testable import LoggingGitHubActions

final class SmokeTests: XCTestCase {
    var logger: Logger = Logger(label: #file, factory: GitHubActionsLogHandler.standardOutput(label:))
    var handler: GitHubActionsLogHandler {
        logger.handler as! GitHubActionsLogHandler
    }

    // MARK: -

    func testDebug() {
        logger.debug("Entered octocatAddition method")
    }

    func testWarning() {
        logger.warning("Missing semicolon")
    }

    func testError() {
        logger.error("Something went wrong")
    }

    func testLogWithMaskedValue() {
        let maskedValue = "Mona The Octocat"
        handler.mask(value: maskedValue)
        logger.debug("\(maskedValue)")
    }

    func testAddSystemPath() {
        let path = "/path/to/dir"
        handler.addSystemPath(path)
    }

    func testSetEnvironmentVariable() {
        let name = "MY_NAME", value = "Mona The Octocat"
        handler.setEnvironmentVariable(name: name, value: value)
    }

    func testSetOutputParameter() {
        let name = "action_fruit", value = "strawberry"
        handler.setOutputParameter(name: name, value: value)
    }

    func testStopStartWorkflowCommands() {
        handler.withoutProcessingWorkflowCommands {
            self.logger.debug("Entered octocatAddition method")
            self.logger.warning("Missing semicolon")
            self.logger.error("Something went wrong")
        }
    }
}
