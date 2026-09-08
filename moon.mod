// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "gf779464/linksweep"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/gf779464/linksweep"

license = "Apache-2.0"

keywords = [ "link-checker", "markdown", "html", "cli" ]

preferred_target = "native"

description = "A MoonBit-native link inventory and local reference checker for Markdown and HTML"

import {
  "moonbitlang/x@0.5.1",
  "moonbitlang/async@0.21.2",
}
