///|
test "GitHub-style heading anchors" {
  let input =
    #|# Hello, World!
    #|## 中文 标题
    #|### Hello, World!
    #|not a heading
  let anchors = extract_anchors(input)
  assert_eq(anchors, ["hello-world", "中文-标题", "hello-world-1"])
}

///|
test "headings allow up to three leading spaces" {
  let anchors = extract_anchors("   ## Install\n    ## code")
  assert_eq(anchors, ["install"])
}

///|
test "JSON report is machine readable" {
  let link : Link = {
    target: "missing.md",
    line: 2,
    column: 4,
    kind: Local,
    source: Markdown,
  }
  let finding : Finding = { link, state: Broken, message: "missing", }
  let json = render_json("README.md", [finding], 1)
  assert_true(json.contains("\"broken\": 1"))
  assert_true(json.contains("\"missing.md\""))
}
