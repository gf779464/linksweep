# Competition roadmap

## Completed: usable vertical slice

- MoonBit-native parser for Markdown links and images
- HTML `href` and `src` extraction
- bare URL discovery and target deduplication
- local reference validation relative to the source document
- live HTTP/HTTPS status checks and an explicit offline mode
- recursive directory scans with build/cache directory exclusions
- same-document and cross-document heading anchor validation
- JSON output for automation
- line/column diagnostics, summaries, and meaningful exit codes
- Windows and Linux CI definition

## Milestone 2: repository scanning (completed)

- recursively scan Markdown and HTML files
- skip known generated directories
- validate same-document and cross-document anchors
- aggregate results across files

Remaining refinement: honor arbitrary `.gitignore` and user exclude patterns.

## Milestone 3: reliable network checks

- bounded concurrency and per-host throttling
- configurable timeout and retry policy
- redirect following and redirect warnings
- HEAD-first strategy with GET fallback
- response cache for repeat scans

## Milestone 4: automation and release

- JSON, CSV, and GitHub Actions report formats
- `.linksweep.json` configuration
- black-box CLI tests and behavioral comparison fixtures
- release binaries for Windows, Linux, and macOS
- publish the library and CLI to Mooncakes

## Acceptance bar

- a fresh clone builds using documented commands
- every public behavior has deterministic tests
- failures produce clean diagnostics and non-zero exit codes
- README examples are executed in CI
- reference projects and licenses are documented
