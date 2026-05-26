///|
pub type Filter = (Value, Array[Value]) -> Value

///|
struct FilterEntry {
  name : String
  filter : Filter
}

///|
fn default_filter_registry() -> Array[FilterEntry] {
  []
}

///|
fn copy_filter_registry(filters : Array[FilterEntry]) -> Array[FilterEntry] {
  filters.copy()
}

///|
fn has_filter(filters : Array[FilterEntry], name : String) -> Bool {
  if is_builtin_filter_name(name) {
    return true
  }
  for entry in filters {
    if entry.name == name {
      return true
    }
  }
  false
}

///|
fn register_filter_entry(
  filters : Array[FilterEntry],
  name : String,
  filter : Filter,
) -> Unit raise MoldError {
  if has_filter(filters, name) {
    raise DuplicateFilter(name)
  }
  filters.push({ name, filter })
}

///|
fn apply_filter(
  filters : Array[FilterEntry],
  value : Value,
  name : String,
  args : Array[Value],
) -> Value raise MoldError {
  match name {
    "upper" => return filter_upper(value, args)
    "lower" => return filter_lower(value, args)
    "trim" => return filter_trim(value, args)
    "default" => return filter_default_impl(value, args)
    "join" => return filter_join(value, args)
    "escape" => return filter_escape(value, args)
    _ => ()
  }
  for entry in filters {
    if entry.name == name {
      return (entry.filter)(value, args)
    }
  }
  raise UnknownFilter(name)
}

///|
fn is_builtin_filter_name(name : String) -> Bool {
  match name {
    "upper" => true
    "lower" => true
    "trim" => true
    "default" => true
    "join" => true
    "escape" => true
    _ => false
  }
}

///|
fn filter_upper(value : Value, _args : Array[Value]) -> Value raise MoldError {
  match value {
    String(s) => String(s.to_upper())
    _ => raise TypeMismatch(("upper requires string", "string"))
  }
}

///|
fn filter_lower(value : Value, _args : Array[Value]) -> Value raise MoldError {
  match value {
    String(s) => String(s.to_lower())
    _ => raise TypeMismatch(("lower requires string", "string"))
  }
}

///|
fn filter_trim(value : Value, _args : Array[Value]) -> Value raise MoldError {
  match value {
    String(s) => String(s.trim().to_owned())
    _ => raise TypeMismatch(("trim requires string", "string"))
  }
}

///|
fn filter_default_impl(value : Value, args : Array[Value]) -> Value noraise {
  match value {
    Null => if args.length() > 0 { args[0] } else { String("") }
    String(s) =>
      if s.length() == 0 && args.length() > 0 {
        args[0]
      } else {
        value
      }
    _ => value
  }
}

///|
fn filter_join(value : Value, args : Array[Value]) -> Value raise MoldError {
  let separator = if args.length() > 0 {
    match args[0] {
      String(s) => s
      _ => ", "
    }
  } else {
    ", "
  }
  match value {
    Array(items) => {
      let buf = StringBuilder::new()
      let mut first = true
      for item in items {
        if !first {
          buf.write_string(separator)
        }
        first = false
        match item {
          String(s) => buf.write_string(s)
          _ => buf.write_string("")
        }
      }
      String(buf.to_string())
    }
    _ => raise TypeMismatch(("join requires array", "array"))
  }
}

///|
fn filter_escape(value : Value, _args : Array[Value]) -> Value raise MoldError {
  String(escape_html(value_to_string(value, "escape")))
}

///|
fn escape_html(text : String) -> String {
  let buf = StringBuilder::new(size_hint=text.length())
  for ch in text {
    match ch {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(ch)
    }
  } nobreak {
    buf.to_string()
  }
}
