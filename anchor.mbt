///|
fn heading_text(line : String) -> String? {
  let chars = line.to_array()
  let mut i = 0
  while i < chars.length() && i < 3 && chars[i] == ' ' {
    i = i + 1
  }
  let start = i
  while i < chars.length() && chars[i] == '#' && i - start < 6 {
    i = i + 1
  }
  if i == start || i >= chars.length() || chars[i] != ' ' {
    return None
  }
  let text = String::from_array(chars[i + 1:]).trim().to_owned()
  if text == "" {
    None
  } else {
    Some(text)
  }
}

///|
pub fn slugify_heading(text : String) -> String {
  let out = StringBuilder()
  let mut pending_dash = false
  let mut wrote = false
  for c in text {
    if c.is_whitespace() {
      pending_dash = wrote
    } else if c.is_ascii_punctuation() && c != '-' && c != '_' {
      continue
    } else {
      if pending_dash && wrote {
        out.write_char('-')
      }
      pending_dash = false
      out.write_char(c.to_ascii_lowercase())
      wrote = true
    }
  }
  out.to_string()
}

///|
pub fn extract_anchors(content : String) -> Array[String] {
  let result : Array[String] = []
  let counts : Map[String, Int] = Map([])
  for line in content.split("\n") {
    match heading_text(line.to_owned()) {
      None => ()
      Some(text) => {
        let base = slugify_heading(text)
        if base != "" {
          let count = counts.get(base).unwrap_or(0)
          let anchor = if count == 0 { base } else { "\{base}-\{count}" }
          counts[base] = count + 1
          result.push(anchor)
        }
      }
    }
  }
  result
}
