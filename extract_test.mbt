///|
test "extract Markdown, HTML and bare links" {
  let input =
    #|[Guide](./docs/guide.md)
    #|<img src="images/a.png">
    #|See https://example.com/help.
  let links = extract_links(input)
  assert_true(links.any(fn(link) { link.target == "./docs/guide.md" }))
  assert_true(links.any(fn(link) { link.target == "images/a.png" }))
  assert_true(links.any(fn(link) { link.target == "https://example.com/help" }))
}

///|
test "classify and deduplicate links" {
  let input = "[one](a.md) [two](a.md) [mail](mailto:a@example.com) [top](#top)"
  let links = unique_links(extract_links(input))
  assert_eq(links.length(), 3)
  assert_true(links.any(fn(link) { link.kind == Local }))
  assert_true(links.any(fn(link) { link.kind == Email }))
  assert_true(links.any(fn(link) { link.kind == Anchor }))
}

///|
test "nested parentheses in Markdown target" {
  let links = extract_links("[spec](docs/a_(draft).md)")
  assert_eq(links[0].target, "docs/a_(draft).md")
}

///|
test "Markdown title is not part of destination" {
  let links = extract_links("[docs](guide.md \"Read the guide\")")
  assert_eq(links[0].target, "guide.md")
}

///|
test "angle-bracket Markdown destination" {
  let links = extract_links("[docs](<guide with spaces.md>)")
  assert_eq(links[0].target, "guide with spaces.md")
}

///|
test "data-href is not treated as href" {
  let links = extract_links("<div data-href=\"not-a-link\"></div>")
  assert_eq(links.length(), 0)
}

///|
test "unquoted HTML href and src attributes are extracted" {
  let links = extract_links(
    "<a href=guide.md>Guide</a><img SRC=images/logo.svg>",
  )
  assert_true(links.any(fn(link) { link.target == "guide.md" }))
  assert_true(links.any(fn(link) { link.target == "images/logo.svg" }))
  assert_true(links.all(fn(link) { link.source == Html }))
}

///|
test "non-network URI schemes are classified as other" {
  let links = extract_links("[phone](tel:123) [inline](data:text/plain,hello)")
  assert_true(links.all(fn(link) { link.kind == Other }))
}

///|
test "reference definition targets are extracted" {
  let links = extract_links(
    "[guide]: docs/guide.md \"Guide\"\n[web]: <https://example.com>",
  )
  assert_true(links.any(fn(link) { link.target == "docs/guide.md" }))
  assert_true(links.any(fn(link) { link.target == "https://example.com" }))
}

///|
test "links inside fenced code are ignored" {
  let input =
    #|```markdown
    #|[example](not-real.md)
    #|```
    #|[real](real.md)
  let links = extract_links(input)
  assert_eq(links.length(), 1)
  assert_eq(links[0].target, "real.md")
}
