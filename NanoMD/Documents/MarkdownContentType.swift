import UniformTypeIdentifiers

extension UTType {
    nonisolated static let markdown = UTType(
        importedAs: "net.daringfireball.markdown",
        conformingTo: .utf8PlainText
    )
}
