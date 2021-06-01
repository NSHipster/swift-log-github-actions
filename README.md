# LoggingGitHubActions

A logging backend for [SwiftLog](https://github.com/apple/swift-log)
that translates logging messages into
[workflow commands for GitHub Actions](https://help.github.com/en/actions/reference/workflow-commands-for-github-actions).

## Requirements

- Swift 5.1+

## Usage

### Conditionally Bootstrapping GitHubActionsLogHandler

```swift
import Logging
import LoggingGitHubActions
import struct Foundation.ProcessInfo

LoggingSystem.bootstrap { label in
    if ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" {
        return GitHubActionsLogHandler.standardOutput(label: label)
    } else {
        return StreamLogHandler.standardOutput(label: label)
    }
}
```

## Using a Logger

Create an instance of `Logger` and log messages accordingly.
When your program is run as a step in a GitHub Actions workflow,
warning and error messages will be formatted in such a way that
it'll be surfaced in the GitHub Actions UI.

```swift
import Logging

let logger = Logger(label: "com.example.MyApp")
logger.error("Something went wrong")
// Prints "::error file=Sources/main.swift,line=5::Something went wrong
```

<img width="636" alt="GitHub Actions UI" src="https://user-images.githubusercontent.com/7659/77580395-294a2c80-6e99-11ea-8c2f-187612b1e945.png">

## Installation

### Swift Package Manager

Add `swift-log-github-actions` as a dependency to your `Package.swift` file.

```swift
.package(url: "https://github.com/NSHipster/swift-log-github-actions.git", from: "1.0.0")
```

Add `"LoggingGitHubActions` to your target's dependencies.

```swift
.target(name: "Example",
        dependencies: ["LoggingGitHubActions"])
```

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))
