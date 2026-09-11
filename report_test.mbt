///|
test "CSV output quotes fields and escapes embedded quotes" {
  let findings : Array[Finding] = [
    {
      link: {
        target: "docs/\"draft\".md",
        line: 3,
        column: 8,
        kind: Local,
        source: Markdown,
      },
      state: Broken,
      message: "missing, check path",
    },
  ]
  inspect(
    render_csv("guide.md", findings),
    content="\"guide.md\",3,8,\"ERROR\",\"docs/\"\"draft\"\".md\",\"missing, check path\"\n",
  )
}
