///|
fn apply_filter(
  value : Value,
  name : String,
  args : Array[Value],
) -> Value raise MoldError {
  match name {
    "upper" => filter_upper(value)
    "lower" => filter_lower(value)
    "trim" => filter_trim(value)
    "default" => filter_default(value, args)
    "join" => filter_join(value, args)
    _ => raise TypeMismatch(("unknown filter: \{name}", "filter"))
  }
}

///|
fn filter_upper(value : Value) -> Value raise MoldError {
  match value {
    String(s) => String(s.to_upper())
    _ => raise TypeMismatch(("upper requires string", "string"))
  }
}

///|
fn filter_lower(value : Value) -> Value raise MoldError {
  match value {
    String(s) => String(s.to_lower())
    _ => raise TypeMismatch(("lower requires string", "string"))
  }
}

///|
fn filter_trim(value : Value) -> Value raise MoldError {
  match value {
    String(s) => String(s.trim().to_owned())
    _ => raise TypeMismatch(("trim requires string", "string"))
  }
}

///|
fn filter_default(value : Value, args : Array[Value]) -> Value noraise {
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
