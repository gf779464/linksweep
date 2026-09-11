///|
fn usage() -> Unit {
  let text =
    #|LinkSweep — find and verify links in Markdown and HTML
    #|
    #|Usage:
    #|  moon run cmd/linksweep -- <file-or-directory> [--offline] [--json] [--exclude=NAME] [--timeout-ms=N]
    #|
    #|Options:
    #|  --offline  Do not access HTTP/HTTPS links
    #|  --json     Emit a JSON array instead of the text report
    #|  --exclude=NAME Skip a directory by its exact name (repeatable)
    #|  --timeout-ms=N HTTP request timeout in milliseconds (default: 10000)
    #|  -V, --version Show the LinkSweep version
    #|  -h, --help Show this help
  println(text)
}

///|
fn without_fragment(target : String) -> String {
  match target.split_once("#") {
    Some((path, _)) => path.to_owned()
    None => target
  }
}

///|
fn fragment(target : String) -> String? {
  match target.split_once("#") {
    Some((_, value)) if value.length() > 0 => Some(value.to_owned())
    _ => None
  }
}

///|
fn contains_anchor(content : String, anchor : String) -> Bool {
  @core.extract_anchors(content).contains(anchor)
}

///|
fn check_local_or_anchor(
  source_file : String,
  source_content : String,
  link : @core.Link,
) -> @core.Finding {
  match link.kind {
    Anchor => {
      let wanted = link.target[1:].to_owned()
      if contains_anchor(source_content, wanted) {
        { link, state: Ok, message: "document anchor exists", }
      } else {
        { link, state: Broken, message: "document anchor not found", }
      }
    }
    Local => {
      let target = without_fragment(link.target)
      let base : @path.Path = source_file
      let joined = base.dirname().join(target).normalize().to_string()
      if !@fs.path_exists(joined) {
        { link, state: Broken, message: "local target not found: \{joined}", }
      } else {
        match fragment(link.target) {
          None => { link, state: Ok, message: "local target exists", }
          Some(wanted) =>
            try {
              let target_content = @fs.read_file_to_string(joined)
              if contains_anchor(target_content, wanted) {
                { link, state: Ok, message: "local target and anchor exist", }
              } else {
                {
                  link,
                  state: Broken,
                  message: "anchor #\{wanted} not found in \{joined}",
                }
              }
            } catch {
              _ =>
                {
                  link,
                  state: Broken,
                  message: "cannot read anchor target: \{joined}",
                }
            }
        }
      }
    }
    _ => { link, state: Skipped, message: "not a local reference", }
  }
}

///|
async fn check_link(
  source_file : String,
  source_content : String,
  link : @core.Link,
  offline : Bool,
  timeout_ms : Int,
) -> @core.Finding {
  match link.kind {
    Web =>
      if offline {
        { link, state: External, message: "not checked in offline mode", }
      } else {
        try {
          let request_target = without_fragment(link.target)
          let code = @async.with_timeout_opt(timeout_ms, () => {
            let (response, body) = @http.get_stream(request_target)
            defer body.close()
            response.code
          })
          match code {
            None =>
              {
                link,
                state: Broken,
                message: "request timed out after \{timeout_ms}ms",
              }
            Some(code) if code >= 200 && code < 400 =>
              { link, state: Ok, message: "HTTP \{code}", }
            Some(code) => { link, state: Broken, message: "HTTP \{code}", }
          }
        } catch {
          _ => { link, state: Broken, message: "network request failed", }
        }
      }
    Email => { link, state: Skipped, message: "email address", }
    Other => { link, state: Skipped, message: "non-checkable URI scheme", }
    Anchor | Local => check_local_or_anchor(source_file, source_content, link)
  }
}

///|
fn is_document(path : String) -> Bool {
  let value : @path.Path = path
  let ext = value.extname().to_owned().to_lower()
  ext == ".md" || ext == ".markdown" || ext == ".html" || ext == ".htm"
}

///|
fn ignored_directory(name : String) -> Bool {
  name == ".git" ||
  name == ".mooncakes" ||
  name == "_build" ||
  name == "testdata" ||
  name == "node_modules"
}

///|
fn collect_documents(
  input : String,
  output : Array[String],
  excludes : Array[String],
) -> Unit {
  let is_file = @fs.is_file(input) catch { _ => false }
  if is_file {
    if is_document(input) {
      output.push(input)
    }
    return
  }
  let is_dir = @fs.is_dir(input) catch { _ => false }
  if !is_dir {
    return
  }
  let entries = @fs.read_dir(input) catch { _ => [] }
  entries.sort()
  for entry in entries {
    if ignored_directory(entry) || excludes.contains(entry) {
      continue
    }
    let base : @path.Path = input
    let child = base.join(entry).normalize().to_string()
    collect_documents(child, output, excludes)
  }
}

///|
async fn scan_file(
  file : String,
  offline : Bool,
  timeout_ms : Int,
) -> @core.ScanReport {
  let content = @fs.read_file_to_string(file)
  let all = @core.extract_links(content)
  let unique = @core.unique_links(all)
  let findings : Array[@core.Finding] = []
  for link in unique {
    findings.push(check_link(file, content, link, offline, timeout_ms))
  }
  {
    file,
    findings,
    summary: @core.summarize(findings, total_occurrences=all.length()),
  }
}

///|
fn parse_positive_int(value : String) -> Int? {
  let parsed = @string.parse_int(value) catch { _ => -1 }
  if parsed > 0 {
    Some(parsed)
  } else {
    None
  }
}

///|
async fn main {
  let args = @env.args()
  if args.any(fn(arg) { arg == "--help" || arg == "-h" }) {
    usage()
    return
  }
  if args.any(fn(arg) { arg == "--version" || arg == "-V" }) {
    println("LinkSweep 0.1.0")
    return
  }
  let offline = args.any(fn(arg) { arg == "--offline" })
  let json_output = args.any(fn(arg) { arg == "--json" })
  let excludes : Array[String] = []
  let mut timeout_ms = 10000
  let mut input : String? = None
  let mut invalid : String? = None
  for i = 1; i < args.length(); i = i + 1 {
    let arg = args[i]
    if arg == "--offline" || arg == "--json" {
      continue
    } else if arg.has_prefix("--exclude=") {
      let name = arg[10:].to_owned()
      if name.is_empty() || name.contains("/") || name.contains("\\") {
        invalid = Some(arg)
      } else {
        excludes.push(name)
      }
    } else if arg.has_prefix("--timeout-ms=") {
      match parse_positive_int(arg[13:].to_owned()) {
        Some(value) => timeout_ms = value
        None => invalid = Some(arg)
      }
    } else if arg.has_prefix("-") {
      invalid = Some(arg)
    } else if input is None {
      input = Some(arg)
    } else {
      invalid = Some(arg)
    }
  }
  match invalid {
    Some(value) => {
      println("Unexpected argument: \{value}")
      usage()
      @sys.exit(2)
      return
    }
    None => ()
  }
  let input = match input {
    Some(value) => value
    None => {
      usage()
      @sys.exit(2)
      return
    }
  }
  let files : Array[String] = []
  collect_documents(input, files, excludes)
  if files.is_empty() {
    println("No Markdown or HTML files found at: \{input}")
    @sys.exit(2)
    return
  }
  let reports : Array[@core.ScanReport] = []
  let mut unreadable = false
  for file in files {
    reports.push(scan_file(file, offline, timeout_ms)) catch {
      _ => {
        unreadable = true
        if !json_output {
          println("ERROR  cannot read \{file}")
        }
      }
    }
  }
  if json_output {
    println(@json.to_json(reports).stringify(indent=2))
  } else {
    let mut total_refs = 0
    let mut total_broken = 0
    for report in reports {
      total_refs = total_refs + report.summary.total
      total_broken = total_broken + report.summary.broken
      if report.summary.total > 0 {
        println(
          @core.render_text(report.file, report.findings, report.summary.total),
        )
      }
    }
    println(
      "Scanned \{reports.length()} document(s), \{total_refs} reference(s), \{total_broken} broken.",
    )
  }
  let broken = reports.any(fn(report) { report.summary.broken > 0 })
  if broken || unreadable {
    @sys.exit(1)
  }
}
