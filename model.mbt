///|
pub(all) enum LinkKind {
  Web
  Local
  Anchor
  Email
  Other
} derive(Eq, Debug, ToJson)

///|
pub(all) enum LinkSource {
  Markdown
  Html
  BareUrl
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Link {
  target : String
  line : Int
  column : Int
  kind : LinkKind
  source : LinkSource
} derive(Eq, Debug, ToJson)

///|
pub(all) enum CheckState {
  Ok
  Broken
  External
  Skipped
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Finding {
  link : Link
  state : CheckState
  message : String
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Summary {
  total : Int
  unique : Int
  ok : Int
  broken : Int
  external : Int
  skipped : Int
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ScanReport {
  file : String
  findings : Array[Finding]
  summary : Summary
} derive(Eq, Debug, ToJson)
