///|
fn main {

}

///|
pub fn mold_render(template : String, data_json : String) -> String {
  try {
    let json = @json.parse(data_json)
    let ctx = @mold.from_json(json)
    try {
      let output = @mold.render(template, ctx)
      "{\"output\":" + json_string(output) + "}"
    } catch {
      err => format_mold_error(err)
    }
  } catch {
    _ => error_json("json", "invalid JSON", 0, 0)
  }
}

///|
fn format_mold_error(err : @mold.MoldError) -> String {
  match err {
    @mold.LexerError((msg, span)) =>
      error_json("template", msg, span.line, span.column)
    @mold.ParserError((msg, span)) =>
      error_json("template", msg, span.line, span.column)
    @mold.UnknownFilter(name) =>
      error_json("template", "unknown filter: " + name, 0, 0)
    @mold.DuplicateFilter(name) =>
      error_json("template", "duplicate filter: " + name, 0, 0)
    @mold.MissingVariable(name) => error_json("template", name, 0, 0)
    @mold.MissingInclude(name) =>
      error_json("template", "missing include: " + name, 0, 0)
    @mold.IncludeDepthExceeded =>
      error_json("template", "include depth exceeded", 0, 0)
    @mold.TypeMismatch((msg, _)) => error_json("template", msg, 0, 0)
  }
}

///|
fn error_json(
  kind : String,
  message : String,
  line : Int,
  column : Int,
) -> String {
  "{\"error\":{\"kind\":\"" +
  kind +
  "\",\"message\":" +
  json_string(message) +
  ",\"line\":" +
  line.to_string() +
  ",\"column\":" +
  column.to_string() +
  "}}"
}

///|
fn json_string(s : String) -> String {
  let buf = StringBuilder::new()
  buf.write_char('"')
  for ch in s {
    match ch {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(ch)
    }
  } nobreak {
    buf.write_char('"')
    buf.to_string()
  }
}
