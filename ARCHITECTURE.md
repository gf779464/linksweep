# Architecture

LinkSweep separates deterministic document analysis from operating-system and network effects.

## Core package

The root `gf779464/linksweep` package has no filesystem or network dependency. It contains:

- `model.mbt`: stable public data types for links, findings, and reports;
- `extract.mbt`: Markdown/HTML extraction and link classification;
- `anchor.mbt`: heading normalization and duplicate-anchor generation;
- `report.mbt`: summaries plus text and JSON serialization.

Keeping this package pure makes it reusable in native programs, browser/Wasm applications, editors, and tests.

## CLI package

`cmd/linksweep` owns effects:

1. parse arguments;
2. recursively discover documents;
3. read each document;
4. call the core extractor;
5. resolve local paths and anchors;
6. perform bounded HTTP requests;
7. render reports and select the exit code.

HTTP requests have a ten-second hard timeout. Generated directories are excluded before traversal. Online checks are optional so CI and air-gapped environments remain deterministic.

## Error contract

Broken links are data, not crashes. Each failure becomes a `Finding` with its source position and explanation. Process-level errors are reserved for invalid command usage and unreadable inputs.

## Test strategy

- black-box tests exercise the public core API;
- white-box CLI tests cover path, anchor, and classification decisions;
- `examples/demo` is a runnable acceptance fixture;
- `testdata/broken.md` proves failure diagnostics and exit status;
- CI compiles and tests on both Windows and Linux.

The reference behavior and deliberately unsupported features are tracked in `COMPATIBILITY.md` so compatibility claims stay auditable.
