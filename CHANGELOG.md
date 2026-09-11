# Changelog

All notable changes to LinkSweep are recorded here. The project follows the
Keep a Changelog structure and uses semantic versioning for published releases.

## [Unreleased]

### Added

- cross-platform release packaging for tagged versions;
- black-box CI smoke tests for the native executable's version, successful
  scan, and broken-link exit status.
- repeatable `--exclude=NAME` directory exclusions for repository scans.
- configurable per-request HTTP timeouts through `--timeout-ms=N`.
- RFC-compatible quoted CSV findings through `--csv`.
- source-positioned GitHub Actions error annotations through `--github`.

### Planned

- configurable include and exclude patterns;
- redirect following, retries, and bounded concurrent HTTP checks;
- CSV and GitHub Actions report formats;
- release binaries for Windows, Linux, and macOS.

## [0.1.0] - 2026-09-08

### Added

- Markdown inline links, images, reference definitions, and bare URL extraction;
- quoted HTML `href` and `src` extraction;
- recursive Markdown and HTML directory scans with generated-directory skips;
- local file, same-document anchor, and cross-document anchor validation;
- live HTTP checks, a 10-second timeout, and explicit offline mode;
- text and JSON reports with source line and column diagnostics;
- stable exit codes for successful scans, broken references, and invalid usage;
- 17 deterministic tests plus Windows and Ubuntu CI.
