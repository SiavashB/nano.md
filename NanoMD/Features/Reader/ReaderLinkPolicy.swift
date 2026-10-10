import Foundation

enum ReaderLinkPolicy {
    static func allowedURL(_ destination: String) -> URL? {
        guard let url = URL(string: destination),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host, !host.isEmpty else {
            return nil
        }
        return url
    }
}
