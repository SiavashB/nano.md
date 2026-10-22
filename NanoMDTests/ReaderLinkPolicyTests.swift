import Testing
@testable import NanoMD

@MainActor
struct ReaderLinkPolicyTests {
    @Test(arguments: [
        "https://example.com", "http://example.com/path?q=value#section",
        "HTTPS://example.com/path", "https://example.com:8443/path", "http://127.0.0.1/path"
    ])
    func allowsExplicitWebDestinations(destination: String) {
        #expect(ReaderLinkPolicy.allowedURL(destination) != nil)
    }

    @Test(arguments: [
        "", "javascript:alert(1)", "data:text/html,hello", "file:///etc/passwd",
        "mailto:person@example.com", "ftp://example.com/file", "x-apple.systempreferences:privacy",
        "notes.md", "../notes.md", "/notes.md", "#heading", "//example.com/path",
        "https:", "https:///", "http:relative", "https://[invalid"
    ])
    func rejectsNonWebRelativeAndHostlessDestinations(destination: String) {
        #expect(ReaderLinkPolicy.allowedURL(destination) == nil)
    }
}
