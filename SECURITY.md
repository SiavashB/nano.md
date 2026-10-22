# Security reporting

Report suspected vulnerabilities in nano.md, its release packages, or the project website through [GitHub's private vulnerability reporting form](https://github.com/SiavashB/nano.md/security/advisories/new).

If you cannot use GitHub, email [feedback@thirdeyeds.com](mailto:feedback@thirdeyeds.com?subject=nano.md%20security%20report) with the subject **nano.md security report**. Do not disclose vulnerabilities or exploit details in public issues or pull requests.

Include:

- The affected release, build, or commit, plus macOS version and hardware where relevant.
- A description of the behavior and potential impact.
- Reproduction steps and a minimal, sanitized sample or proof of concept.

Use disposable files for reproduction and omit private documents, credentials, and unrelated personal information. Coordinate public disclosure through the private report.

The app treats document content as untrusted: HTML stays literal, images and remote resources are not loaded, and only explicitly activated HTTP/HTTPS document links open in the browser. The sandbox limits file access to user-selected resources. The Mac app has no telemetry or network entitlement.

For ordinary bugs, use the [bug report form](https://github.com/SiavashB/nano.md/issues/new?template=bug_report.yml).
