# LinkSweep / 链探

LinkSweep is a MoonBit-native link inventory and local-reference checker for Markdown and HTML. It helps writers, documentation teams, and open-source projects find missing files, images, duplicated URLs, and web links that need verification.

Unlike a simple URL pinger, LinkSweep understands where a link appears. It resolves local paths relative to each source document, checks generated heading anchors, and returns a failing exit code that CI systems can enforce.

## Current release

Version 0.1 provides an end-to-end scan:

- extracts Markdown links and images;
- extracts HTML `href` and `src` attributes;
- discovers bare HTTP/HTTPS URLs;
- classifies web, local, anchor, and email links;
- deduplicates targets while preserving their first location;
- validates local files relative to the source document;
- checks HTTP/HTTPS status codes unless `--offline` is used;
- validates same-document and cross-document heading anchors;
- recursively scans `.md`, `.markdown`, `.mdx`, `.html`, and `.htm` files;
- emits human-readable text, structured JSON, CSV, or GitHub annotations;
- produces a line-and-column report and fails on broken local references.

Generated directories such as `.git`, `.mooncakes`, `_build`, `node_modules`, and `testdata` are skipped during recursive scans.

The current release already includes recursive directory scanning, a configurable
network timeout, and JSON output. Configuration files, retry policies, redirect
following, and additional report formats remain future milestones.

## Run

Prerequisite: the [MoonBit toolchain](https://www.moonbitlang.com/download/).

```shell
moon update
moon test
moon run cmd/linksweep -- README.mbt.md
moon run cmd/linksweep -- README.mbt.md --offline
moon run cmd/linksweep -- examples/demo --offline
moon run cmd/linksweep -- examples/demo --offline --json
moon run cmd/linksweep -- examples/demo --offline --csv
moon run cmd/linksweep -- testdata/broken.md --offline --github
moon run cmd/linksweep -- ./docs --offline --exclude=vendor --exclude=generated
moon run cmd/linksweep -- README.mbt.md --timeout-ms=5000
```

Options may appear before or after the input path:

```shell
moon run cmd/linksweep -- --offline --json ./docs
moon run cmd/linksweep -- --version
```

Exit codes:

- `0`: every checked link passed;
- `1`: at least one link is broken or a document could not be read;
- `2`: invalid input or command-line usage.

`--exclude=NAME` skips directories whose exact name matches `NAME`; the option
may be repeated. Generated directories are still excluded automatically.

`--timeout-ms=N` sets the timeout for each HTTP request to a positive number of
milliseconds. It defaults to 10000 and has no effect in offline mode.

`--json` emits complete scan reports for automation. `--csv` emits one finding
per row using the columns `file,line,column,state,target,message`; the two
formats are mutually exclusive.

`--github` emits each broken link as an `::error` workflow command with its
file, line, and column. GitHub Actions displays these directly as annotations.

## Supported syntax

- inline Markdown links and images, including destinations in angle brackets;
- Markdown reference definitions;
- quoted and unquoted HTML `href` and `src` attributes;
- bare HTTP/HTTPS URLs;
- ATX headings (`#` through `######`) and duplicate heading suffixes;
- `mailto:`, `tel:`, `data:`, and `javascript:` classification;
- fenced code blocks are excluded from link extraction.

Current limitations are explicit: redirects are reported by their first response,
and GitHub-style anchor normalization is implemented for common headings rather
than every Unicode edge case.

## Verification

The repository runs the following checks on both Ubuntu and Windows for every
push and pull request:

```shell
moon update
moon check --target native
moon test --target native
moon fmt --check
moon run cmd/linksweep --target native -- examples/demo --offline
```

The current test suite contains 22 deterministic tests covering extraction,
classification, local references, and heading anchors. The demonstration scan
is also executed in CI so the documented command cannot silently drift.

## Project direction

The project is an independent MoonBit implementation inspired by established link checkers such as [Markup Link Checker](https://github.com/becheran/mlc). Compatibility work will be documented with fixtures and behavioral comparisons. No source code is copied from the reference implementation.

See `ARCHITECTURE.md`, `COMPATIBILITY.md`, `ROADMAP.md`, and `CHANGELOG.md`
for engineering boundaries, provenance, competition milestones, and a dated
record of user-visible changes.

## Release build

```shell
moon build --target native --release cmd/linksweep
```

On Windows the executable is generated at `_build/native/release/build/cmd/linksweep/linksweep.exe`.

Pushing a version tag such as `v0.1.0` runs the release workflow on Windows and
Ubuntu, executes the test suite, builds both native binaries, and attaches them
to a GitHub Release. The workflow can also be run manually to verify packaging
without publishing a release.

## License

Apache-2.0. See `LICENSE`.
