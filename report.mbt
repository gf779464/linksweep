///|
pub fn summarize(
  findings : Array[Finding],
  total_occurrences? : Int = -1,
) -> Summary {
  let mut ok = 0
  let mut broken = 0
  let mut external = 0
  let mut skipped = 0
  for finding in findings {
    match finding.state {
      Ok => ok = ok + 1
      Broken => broken = broken + 1
      External => external = external + 1
      Skipped => skipped = skipped + 1
    }
  }
  {
    total: if total_occurrences < 0 {
      findings.length()
    } else {
      total_occurrences
    },
    unique: findings.length(),
    ok,
    broken,
    external,
    skipped,
  }
}

///|
fn state_label(state : CheckState) -> String {
  match state {
    Ok => "OK"
    Broken => "ERROR"
    External => "WEB"
    Skipped => "SKIP"
  }
}

///|
pub fn render_text(
  file : String,
  findings : Array[Finding],
  total : Int,
) -> String {
  let buffer = StringBuilder()
  for finding in findings {
    buffer.write_string(file)
    buffer.write_string(":")
    buffer.write_string(finding.link.line.to_string())
    buffer.write_string(":")
    buffer.write_string(finding.link.column.to_string())
    buffer.write_string("  ")
    buffer.write_string(state_label(finding.state))
    buffer.write_string("  ")
    buffer.write_string(finding.link.target)
    if finding.message != "" {
      buffer.write_string(" — ")
      buffer.write_string(finding.message)
    }
    buffer.write_char('\n')
  }
  let summary = summarize(findings, total_occurrences=total)
  buffer.write_string(
    "\nChecked \{summary.total} references (\{summary.unique} unique): \{summary.ok} passed, \{summary.broken} broken, \{summary.external} web unchecked, \{summary.skipped} skipped\n",
  )
  buffer.to_string()
}

///|
pub fn render_json(
  file : String,
  findings : Array[Finding],
  total : Int,
) -> String {
  let report : ScanReport = {
    file,
    findings,
    summary: summarize(findings, total_occurrences=total),
  }
  @json.to_json(report).stringify(indent=2)
}

///|
fn csv_field(value : String) -> String {
  "\"\{value.replace_all(old="\"", new="\"\"")}\""
}

///|
pub fn render_csv(file : String, findings : Array[Finding]) -> String {
  let buffer = StringBuilder()
  for finding in findings {
    buffer.write_string(csv_field(file))
    buffer.write_string(",")
    buffer.write_string(finding.link.line.to_string())
    buffer.write_string(",")
    buffer.write_string(finding.link.column.to_string())
    buffer.write_string(",")
    buffer.write_string(csv_field(state_label(finding.state)))
    buffer.write_string(",")
    buffer.write_string(csv_field(finding.link.target))
    buffer.write_string(",")
    buffer.write_string(csv_field(finding.message))
    buffer.write_char('\n')
  }
  buffer.to_string()
}

///|
fn github_escape(value : String, property : Bool) -> String {
  let escaped = value
    .replace_all(old="%", new="%25")
    .replace_all(old="\r", new="%0D")
    .replace_all(old="\n", new="%0A")
  if property {
    escaped.replace_all(old=",", new="%2C").replace_all(old=":", new="%3A")
  } else {
    escaped
  }
}

///|
pub fn render_github(file : String, findings : Array[Finding]) -> String {
  let buffer = StringBuilder()
  for finding in findings {
    if finding.state == Broken {
      buffer.write_string("::error file=")
      buffer.write_string(github_escape(file, true))
      buffer.write_string(",line=")
      buffer.write_string(finding.link.line.to_string())
      buffer.write_string(",col=")
      buffer.write_string(finding.link.column.to_string())
      buffer.write_string("::")
      buffer.write_string(github_escape(finding.message, false))
      buffer.write_string(" — ")
      buffer.write_string(github_escape(finding.link.target, false))
      buffer.write_char('\n')
    }
  }
  buffer.to_string()
}
