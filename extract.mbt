///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\r' || c == '\n'
}

///|
fn classify(target : String) -> LinkKind {
  if target.has_prefix("http://") || target.has_prefix("https://") {
    Web
  } else if target.has_prefix("mailto:") {
    Email
  } else if target.has_prefix("tel:") ||
    target.has_prefix("data:") ||
    target.has_prefix("javascript:") {
    Other
  } else if target.has_prefix("#") {
    Anchor
  } else {
    Local
  }
}

///|
fn add_link(
  links : Array[Link],
  target : String,
  line : Int,
  column : Int,
  source : LinkSource,
) -> Unit {
  let cleaned = target.trim().to_owned()
  if cleaned != "" {
    links.push({
      target: cleaned,
      line,
      column,
      kind: classify(cleaned),
      source,
    })
  }
}

///|
fn markdown_destination(raw : String) -> String {
  let value = raw.trim().to_owned()
  if value.has_prefix("<") && value.has_suffix(">") && value.length() >= 2 {
    return value[1:value.length() - 1].to_owned()
  }
  let chars = value.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    if is_space(chars[i]) {
      return String::from_array(chars[:i])
    }
  }
  value
}

///|
fn scan_markdown_line(
  line_text : String,
  line_no : Int,
  out : Array[Link],
) -> Unit {
  let chars = line_text.to_array()
  let n = chars.length()
  let mut i = 0
  while i + 2 < n {
    if chars[i] == ']' && chars[i + 1] == '(' {
      let start = i + 2
      let mut j = start
      let mut depth = 0
      while j < n && (chars[j] != ')' || depth > 0) {
        if chars[j] == '(' {
          depth = depth + 1
        } else if chars[j] == ')' {
          depth = depth - 1
        }
        j = j + 1
      }
      if j < n {
        add_link(
          out,
          markdown_destination(String::from_array(chars[start:j])),
          line_no,
          start + 1,
          Markdown,
        )
        i = j + 1
        continue
      }
    }
    i = i + 1
  }
}

///|
fn scan_reference_definition(
  line_text : String,
  line_no : Int,
  out : Array[Link],
) -> Unit {
  let chars = line_text.to_array()
  let mut i = 0
  while i < chars.length() && i < 3 && chars[i] == ' ' {
    i = i + 1
  }
  if i >= chars.length() || chars[i] != '[' {
    return
  }
  while i + 1 < chars.length() && !(chars[i] == ']' && chars[i + 1] == ':') {
    i = i + 1
  }
  if i + 1 >= chars.length() {
    return
  }
  i = i + 2
  while i < chars.length() && is_space(chars[i]) {
    i = i + 1
  }
  if i >= chars.length() {
    return
  }
  let start = i
  if chars[i] == '<' {
    i = i + 1
    while i < chars.length() && chars[i] != '>' {
      i = i + 1
    }
    if i < chars.length() {
      add_link(
        out,
        String::from_array(chars[start + 1:i]),
        line_no,
        start + 2,
        Markdown,
      )
    }
  } else {
    while i < chars.length() && !is_space(chars[i]) {
      i = i + 1
    }
    add_link(
      out,
      String::from_array(chars[start:i]),
      line_no,
      start + 1,
      Markdown,
    )
  }
}

///|
fn fence_marker(line : String) -> String? {
  let value = line.trim_start().to_owned()
  if value.has_prefix("```") {
    Some("```")
  } else if value.has_prefix("~~~") {
    Some("~~~")
  } else {
    None
  }
}

///|
fn ascii_lower(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() + 32).unsafe_to_char()
  } else {
    c
  }
}

///|
fn starts_at_ci(chars : Array[Char], at : Int, needle : String) -> Bool {
  let expected = needle.to_array()
  if at + expected.length() > chars.length() {
    return false
  }
  for i = 0; i < expected.length(); i = i + 1 {
    if ascii_lower(chars[at + i]) != ascii_lower(expected[i]) {
      return false
    }
  }
  true
}

///|
fn scan_html_attr(
  line_text : String,
  line_no : Int,
  attr : String,
  out : Array[Link],
) -> Unit {
  let chars = line_text.to_array()
  let mut i = 0
  while i + attr.length() < chars.length() {
    let boundary = i == 0 || is_space(chars[i - 1]) || chars[i - 1] == '<'
    if boundary && starts_at_ci(chars, i, attr) {
      let mut j = i + attr.length()
      while j < chars.length() && is_space(chars[j]) {
        j = j + 1
      }
      if j < chars.length() && chars[j] == '=' {
        j = j + 1
        while j < chars.length() && is_space(chars[j]) {
          j = j + 1
        }
        if j < chars.length() && (chars[j] == '\"' || chars[j] == '\'') {
          let quote = chars[j]
          let start = j + 1
          j = start
          while j < chars.length() && chars[j] != quote {
            j = j + 1
          }
          if j < chars.length() {
            add_link(
              out,
              String::from_array(chars[start:j]),
              line_no,
              start + 1,
              Html,
            )
            i = j + 1
            continue
          }
        } else if j < chars.length() && chars[j] != '>' {
          let start = j
          while j < chars.length() && !is_space(chars[j]) && chars[j] != '>' {
            j = j + 1
          }
          if j > start {
            add_link(
              out,
              String::from_array(chars[start:j]),
              line_no,
              start + 1,
              Html,
            )
            i = j
            continue
          }
        }
      }
    }
    i = i + 1
  }
}

///|
fn scan_bare_urls(line_text : String, line_no : Int, out : Array[Link]) -> Unit {
  let chars = line_text.to_array()
  let mut i = 0
  while i < chars.length() {
    let is_url = starts_at_ci(chars, i, "https://") ||
      starts_at_ci(chars, i, "http://")
    let embedded = i > 0 &&
      (chars[i - 1] == '(' || chars[i - 1] == '\"' || chars[i - 1] == '\'')
    if is_url && !embedded {
      let start = i
      let mut j = i
      while j < chars.length() &&
            !is_space(chars[j]) &&
            chars[j] != '<' &&
            chars[j] != '>' &&
            chars[j] != '\"' &&
            chars[j] != '\'' {
        j = j + 1
      }
      while j > start &&
            (
              chars[j - 1] == ')' ||
              chars[j - 1] == ']' ||
              chars[j - 1] == ',' ||
              chars[j - 1] == '.'
            ) {
        j = j - 1
      }
      add_link(
        out,
        String::from_array(chars[start:j]),
        line_no,
        start + 1,
        BareUrl,
      )
      i = if j > i { j } else { i + 1 }
    } else {
      i = i + 1
    }
  }
}

///|
pub fn extract_links(content : String) -> Array[Link] {
  let result : Array[Link] = []
  let mut line_no = 1
  let mut fence : String? = None
  for view in content.split("\n") {
    let line = view.to_owned()
    match fence_marker(line) {
      Some(marker) if fence is None => {
        fence = Some(marker)
        line_no = line_no + 1
        continue
      }
      Some(marker) if fence == Some(marker) => {
        fence = None
        line_no = line_no + 1
        continue
      }
      _ => ()
    }
    if fence is Some(_) {
      line_no = line_no + 1
      continue
    }
    scan_markdown_line(line, line_no, result)
    scan_reference_definition(line, line_no, result)
    scan_html_attr(line, line_no, "href", result)
    scan_html_attr(line, line_no, "src", result)
    scan_bare_urls(line, line_no, result)
    line_no = line_no + 1
  }
  result
}

///|
pub fn unique_links(links : Array[Link]) -> Array[Link] {
  let seen : Map[String, Bool] = Map([])
  let result : Array[Link] = []
  for link in links {
    if !seen.contains(link.target) {
      seen[link.target] = true
      result.push(link)
    }
  }
  result
}
