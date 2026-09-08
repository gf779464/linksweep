# Compatibility and provenance

LinkSweep is an independent MoonBit implementation. It studies established link-checking tools to identify useful behavior, but it does not copy their source code.

## Reference implementation

- Project: Markup Link Checker (`becheran/mlc`)
- Source: <https://github.com/becheran/mlc>
- License: MIT
- Studied behavior: file discovery, Markdown/HTML link checks, ignore controls, throttling, CSV diagnostics, and CI integration

## Initial compatibility scope

| Behavior | LinkSweep 0.1 |
| --- | --- |
| Scan a single Markdown file | Supported |
| Extract Markdown links and images | Supported |
| Extract HTML `href` and `src` | Supported |
| Check relative files | Supported |
| Check HTTP/HTTPS status | Supported |
| Offline mode | Supported |
| Recursive directory scan | Supported |
| Anchor validation | Supported |
| Ignore configuration | Next milestone |
| JSON output | Supported |
| CSV output | Planned |

Compatibility claims will only be expanded when backed by black-box fixtures.
