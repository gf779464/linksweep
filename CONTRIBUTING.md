# Contributing

## Setup

Install the current MoonBit toolchain, then run:

```shell
moon update
moon check --target native --deny-warn
moon test --target native
moon fmt --check
moon run cmd/linksweep --target native -- examples/demo --offline
```

## Change requirements

- add a focused test for every behavior change;
- keep extraction logic independent from filesystem and network access;
- preserve clean stdout in JSON mode;
- do not weaken exit-code behavior;
- document compatibility claims with fixtures;
- run `moon info` when a public API changes.

## Commit structure

Use small commits that each represent a working engineering step, such as one parser feature plus its tests. Empty commits and artificial code splitting are not accepted.
