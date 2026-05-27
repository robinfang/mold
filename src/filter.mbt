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
  let peeled = match value {
    Safe(inner) => inner
    _ => value
  }
  let result = match name {
    "upper" => filter_upper(peeled, args)
    "lower" => filter_lower(peeled, args)
    "trim" => filter_trim(peeled, args)
    "default" => filter_default_impl(peeled, args)
    "join" => filter_join(peeled, args)
    "escape" => filter_escape(peeled, args)
    "safe" => filter_safe(value, args)
    _ => {
      for entry in filters {
        if entry.name == name {
          let inner = (entry.filter)(peeled, args)
          match value {
            Safe(_) => return Safe(inner)
            _ => return inner
          }
        }
      }
      raise UnknownFilter(name)
    }
  }
  match value {
    Safe(_) => Safe(result)
    _ => result
  }
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
    "safe" => true
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

///|
fn filter_safe(value : Value, _args : Array[Value]) -> Value noraise {
  Safe(value)
}

