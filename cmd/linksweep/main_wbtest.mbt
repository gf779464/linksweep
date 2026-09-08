///|
test "document extension matching is case insensitive" {
  assert_true(is_document("README.MD"))
  assert_true(is_document("page.html"))
  assert_false(is_document("image.png"))
}

///|
test "generated directories are ignored" {
  assert_true(ignored_directory(".git"))
  assert_true(ignored_directory("_build"))
  assert_true(ignored_directory("testdata"))
  assert_false(ignored_directory("docs"))
}

///|
test "fragment parsing" {
  assert_eq(fragment("guide.md#install"), Some("install"))
  assert_eq(fragment("guide.md"), None)
  assert_eq(without_fragment("guide.md#install"), "guide.md")
}

///|
test "same-document anchor validation" {
  let link : @core.Link = {
    target: "#quick-start",
    line: 1,
    column: 1,
    kind: Anchor,
    source: Markdown,
  }
  let ok = check_local_or_anchor("README.md", "# Quick Start", link)
  assert_eq(ok.state, Ok)
  let broken = check_local_or_anchor("README.md", "# Other", link)
  assert_eq(broken.state, Broken)
}

///|
test "other URI schemes are skipped" {
  let link : @core.Link = {
    target: "javascript:void(0)",
    line: 1,
    column: 1,
    kind: Other,
    source: Html,
  }
  let finding = check_local_or_anchor("page.html", "", link)
  assert_eq(finding.state, Skipped)
}
