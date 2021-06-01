import Logging
@testable import LoggingGitHubActions

final class MockTextOutputStream {
    public private(set) var lines: [String] = []

    public init(_ body: (Logger) -> Void) {
        let logger = Logger(label: #file) { label in
            GitHubActionsLogHandler(outputStream: self)
        }

        body(logger)
    }
}

extension MockTextOutputStream: TextOutputStream {
    func write(_ string: String) {
        lines.append(string)
    }
}
