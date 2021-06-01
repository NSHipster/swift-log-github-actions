import Logging
import struct Foundation.UUID

/**
 A logger for GitHub Actions workflows.

 See ["Workflow commands for GitHub Actions."](https://help.github.com/en/actions/reference/workflow-commands-for-github-actions)
 */
public struct GitHubActionsLogHandler: LogHandler {
    private var outputStream: TextOutputStream

    /**
     Get or set the configured log level.
    */
    public var logLevel: Logger.Level = .debug

    /**
     Get or set the entire metadata storage as a dictionary.
     */
    public var metadata: Logger.Metadata = [:]

    /**
     Add, remove, or change the logging metadata.

     - Note: `LogHandler`s must treat logging metadata as a value type.
             This means that the change in metadata must only affect this very `LogHandler`.

     - Parameters:
        - metadataKey: The key for the metadata item
     */
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }

    /**
     Returns a handler that logs to standard output (`STDOUT`).

     - Parameters:
        - label: A label identifying the logging handler.
     */
    public static func standardOutput(label: String) -> GitHubActionsLogHandler {
        return GitHubActionsLogHandler(outputStream: StandardTextOutputStream())
    }

    init(outputStream: TextOutputStream) {
        self.outputStream = outputStream
    }

    // MARK: - Logging messages

    /**
     Prints a message to the log at the specified level.

     This method is called when a `LogHandler` must emit a log message.
     There is no need for the `LogHandler` to check
     if the `level` is above or below the configured `logLevel`
     as `Logger` already performed this check and determined that a message should be logged.

            ::{level} file={name},line={line}::{message}

     - Note: You must create a secret named `ACTIONS_STEP_DEBUG` with the value `true`
             to see the debug messages set by this command in the log.
             To learn more about creating secrets and using them in a step, see
             ["Creating and using encrypted secrets."](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets)

     - Parameters:
        - level: The log level the message was logged at.
        - message: The message to log. To obtain a `String` representation call `message.description`.
        - metadata: The metadata associated to this log message.
        - file: The file the log message was emitted from.
        - function: The function the log line was emitted from.
        - line: The line the log message was emitted from.
     */
    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        let command: String
        switch level {
        case .error...:
            command = "error"
        case .warning:
            command = "warning"
        default:
            command = "debug"
        }

        var parameters = self.metadata
        if let metadata = metadata {
            parameters.merge(metadata, uniquingKeysWith: { (_, new) in new })
        }
        parameters["file"] = "\(file)"
        parameters["line"] = "\(line)"

        echo(command: command, parameters: parameters.map { ($0.key, $0.value.description) }, value: message.description)
    }

    // MARK: - Masking a value in log

    /**
     Masking a value prevents a string or variable from being printed in the log.
     Each masked word separated by whitespace is replaced with the `*` character.
     You can use an environment variable or string for the mask's value.

            ::add-mask::{value}
    */
    public func mask(value: String) {
        echo(command: "add-mask", value: value)
    }

    // MARK: - Setting an environment variable

    /**
     Creates or updates an environment variable
     for any actions running next in a job.

     The action that creates or updates the environment variable
     does not have access to the new value,
     but all subsequent actions in a job will have access.
     Environment variables are case-sensitive and you can include punctuation.

            ::set-env name={name}::{value}

     - Parameters:
     - name: The environment variable name
     - value: The environment variable value
     */
    public func setEnvironmentVariable(name: String, value: String) {
        echo(command: "set-env", parameters: [("name", name)], value: value)
    }

    // MARK: - Setting an output parameter

    /**
     Sets an action's output parameter.

     Optionally, you can also declare output parameters in an action's metadata file.
     For more information, see ["Metadata syntax for GitHub Actions."](https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions)

            ::set-output name={name}::{value}

     - Parameters:
        - name: The environment variable name
        - value: The environment variable value
     */
    public func setOutputParameter(name: String, value: String) {
        echo(command: "set-output", parameters: [("name", name)], value: value)
    }

    // MARK: - Adding a system path

    /**
     Prepends a directory to the system `PATH` variable
     for all subsequent actions in the current job.

     The currently running action cannot access the new path variable.

            ::add-path::{path}

     - Parameters:
        - path: The directory path to prepend to the system `PATH` variable.

     */
    public func addSystemPath(_ path: String) {
        echo(command: "add-path", value: path)
    }

    // MARK: - Ignoring workflow commands

    /**
     Performs the specified closure
     without processing any workflow commands.

     You can use this function to log dynamic values
     without accidentally running a workflow command.
     For example,
     you could stop logging to output an entire script that has comments.

            ::stop-commands::{token}
            ...
            ::{token}::

     - Parameters:
        - body: Work to be performed without running workflow commands.
     */
    public func withoutProcessingWorkflowCommands(_ body: () -> Void) {
        let token = UUID()
        echo(command: "stop-commands", value: "\(token)")
        body()
        echo(command: "\(token)")
    }

    // MARK: -

    private func echo(command: String, parameters: [(key: String, value: String)] = [], value: String? = nil) {
        var output = "::\(command)"
        if !parameters.isEmpty {
            output += " \(parameters.map { "\($0)=\($1)" }.sorted().joined(separator: ","))"
        }
        output += "::\(value ?? "")"

        var outputStream = self.outputStream
        outputStream.write(output)
    }
}

// MARK: -

fileprivate struct StandardTextOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        print(string)
    }
}
