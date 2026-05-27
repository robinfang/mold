///|
fn resolve_with_scope(
  ctx : Value,
  path : Array[String],
  expr : String,
  scope : Map[String, Value],
) -> Value raise MoldError {
  if path.length() == 0 {
    return ctx
  }
  let first = path[0]
  let mut value = match scope.get(first) {
    Some(v) => v
    None =>
      match ctx {
        Object(fields) =>
          match fields.get(first) {
            Some(next) => next
            None => raise MissingVariable("missing variable: \{expr}")
          }
        _ => raise MissingVariable("missing variable: \{expr}")
      }
  }
  for i = 1; i < path.length(); i = i + 1 {
    let segment = path[i]
    value = match value {
      Object(fields) =>
        match fields.get(segment) {
          Some(next) => next
          None => raise MissingVariable("missing variable: \{expr}")
        }
      _ =>
        raise TypeMismatch(("cannot access '\{segment}' in \{expr}", "object"))
    }
  } nobreak {
    value
  }
}

///|
fn value_to_string(value : Value, expr : String) -> String raise MoldError {
  match value {
    Null => ""
    Bool(boolean) => if boolean { "true" } else { "false" }
    Int(integer) => integer.to_string()
    Float(number) => number.to_string()
    String(text) => text
    Safe(inner) => value_to_string(inner, expr)
    Array(_) =>
      raise TypeMismatch(("cannot render array value: \{expr}", "scalar"))
    Object(_) =>
      raise TypeMismatch(("cannot render object value: \{expr}", "scalar"))
  }
}
