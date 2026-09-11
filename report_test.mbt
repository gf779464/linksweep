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

///|
test "GitHub output includes only broken findings and escapes commands" {
  let findings : Array[Finding] = [
    {
      link: {
        target: "missing.md",
        line: 4,
        column: 2,
        kind: Local,
        source: Markdown,
      },
      state: Broken,
      message: "missing 100%",
    },
    {
      link: {
        target: "ok.md",
        line: 5,
        column: 2,
        kind: Local,
        source: Markdown,
      },
      state: Ok,
      message: "exists",
    },
  ]
  inspect(
    render_github("docs/a,b.md", findings),
    content="::error file=docs/a%2Cb.md,line=4,col=2::missing 100%25 — missing.md\n",
  )
}
