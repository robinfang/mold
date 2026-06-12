///|
pub struct TemplateInspection {
  variables : Array[String]
  filters : Array[String]
  includes : Array[String]
}

///|
fn inspect_nodes(nodes : Array[Node]) -> TemplateInspection {
  let result = TemplateInspection::{ variables: [], filters: [], includes: [] }
  inspect_nodes_scoped(nodes, [], result)
  result
}

///|
fn inspect_nodes_scoped(
  nodes : Array[Node],
  locals : Array[String],
  result : TemplateInspection,
) -> Unit {
  for node in nodes {
    match node {
      Text(_) => ()
      Interpolation(expr) => inspect_expr(expr, locals, result)
      If(cond, then_nodes, else_nodes) => {
        inspect_expr(cond, locals, result)
        inspect_nodes_scoped(then_nodes, locals, result)
        inspect_nodes_scoped(else_nodes, locals, result)
      }
      For(item_name, iterable, body) => {
        inspect_expr(iterable, locals, result)
        let loop_locals = locals_with(locals, item_name)
        inspect_nodes_scoped(body, loop_locals, result)
      }
      Include(name) => add_unique(result.includes, name)
    }
  }
}

///|
fn inspect_expr(
  expr : Expr,
  locals : Array[String],
  result : TemplateInspection,
) -> Unit {
  match expr {
    Path(segments) => inspect_path(segments, locals, result)
    StringLiteral(_) => ()
    IntLiteral(_) => ()
    FloatLiteral(_) => ()
    BoolLiteral(_) => ()
    NullLiteral => ()
    FilterCall(base, name, args) => {
      inspect_expr(base, locals, result)
      add_unique(result.filters, name)
      for arg in args {
        inspect_expr(arg, locals, result)
      }
    }
    Binary(left, _, right) => {
      inspect_expr(left, locals, result)
      inspect_expr(right, locals, result)
    }
    Unary(_, inner) => inspect_expr(inner, locals, result)
  }
}

///|
fn inspect_path(
  segments : Array[String],
  locals : Array[String],
  result : TemplateInspection,
) -> Unit {
  if segments.length() == 0 {
    return
  }
  let root = segments[0]
  if root == "loop" || contains_string(locals, root) {
    return
  }
  add_unique(result.variables, segments.join("."))
}

///|
fn locals_with(locals : Array[String], name : String) -> Array[String] {
  let next : Array[String] = []
  for item in locals {
    next.push(item)
  }
  next.push(name)
  next
}

///|
fn add_unique(values : Array[String], value : String) -> Unit {
  if !contains_string(values, value) {
    values.push(value)
  }
}

///|
fn contains_string(values : Array[String], value : String) -> Bool {
  for existing in values {
    if existing == value {
      return true
    }
  }
  false
}
