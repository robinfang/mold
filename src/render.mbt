///|
fn render_ast(
  nodes : Array[Node],
  ctx : Value,
  source : String,
  filters : Array[FilterEntry],
  loader : Loader?,
  includes : Array[CompiledInclude],
  autoescape : Bool,
) -> String raise MoldError {
  render_ast_scoped(
    nodes,
    ctx,
    source,
    Map::from_array([]),
    filters,
    loader,
    includes,
    0,
    autoescape,
  )
}

///|
fn render_ast_scoped(
  nodes : Array[Node],
  ctx : Value,
  source : String,
  scope : Map[String, Value],
  filters : Array[FilterEntry],
  loader : Loader?,
  includes : Array[CompiledInclude],
  depth : Int,
  autoescape : Bool,
) -> String raise MoldError {
  let builder = StringBuilder::new(size_hint=source.length())
  for node in nodes {
    match node {
      Text(text) => builder.write_string(text)
      Interpolation(expr) => {
        let value = eval_expr(expr, ctx, scope, filters)
        if autoescape {
          match value {
            Safe(inner) => builder.write_string(value_to_string(inner, ""))
            _ => {
              let escaped = filter_escape(value, [])
              builder.write_string(value_to_string(escaped, ""))
            }
          }
        } else {
          builder.write_string(value_to_string(value, ""))
        }
      }
      If(cond_expr, then_nodes, else_nodes) => {
        let cond = eval_expr(cond_expr, ctx, scope, filters)
        if is_truthy(cond) {
          builder.write_string(
            render_ast_scoped(
              then_nodes, ctx, source, scope, filters, loader, includes, depth, autoescape,
            ),
          )
        } else {
          builder.write_string(
            render_ast_scoped(
              else_nodes, ctx, source, scope, filters, loader, includes, depth, autoescape,
            ),
          )
        }
      }
      For(item_name, iterable_expr, body) => {
        let iterable = eval_expr(iterable_expr, ctx, scope, filters)
        match iterable {
          Array(items) => {
            let len = items.length()
            let mut i = 0
            for item in items {
              let loop_obj = Object(
                Map::from_array([
                  ("index", Int(i + 1)),
                  ("index0", Int(i)),
                  ("first", Bool(i == 0)),
                  ("last", Bool(i == len - 1)),
                  ("length", Int(len)),
                ]),
              )
              let item_scope : Map[String, Value] = Map::from_array([
                (item_name, item),
                ("loop", loop_obj),
              ])
              builder.write_string(
                render_ast_scoped(
                  body, ctx, source, item_scope, filters, loader, includes, depth,
                  autoescape,
                ),
              )
              i = i + 1
            }
          }
          _ => raise TypeMismatch(("cannot iterate", "array"))
        }
      }
      Include(name) => {
        if depth >= 10 {
          raise IncludeDepthExceeded
        }
        match find_compiled_include(includes, name) {
          Some(entry) =>
            builder.write_string(
              render_ast_scoped(
                entry.ast,
                ctx,
                entry.source,
                scope,
                filters,
                loader,
                includes,
                depth + 1,
                autoescape,
              ),
            )
          None =>
            match loader {
              None => raise MissingInclude(name)
              Some(load) =>
                match load(name) {
                  None => raise MissingInclude(name)
                  Some(included_source) => {
                    let included_tokens = lex(included_source)
                    let included_nodes = parse(included_tokens)
                    builder.write_string(
                      render_ast_scoped(
                        included_nodes,
                        ctx,
                        included_source,
                        scope,
                        filters,
                        loader,
                        includes,
                        depth + 1,
                        autoescape,
                      ),
                    )
                  }
                }
            }
        }
      }
    }
  } nobreak {
    builder.to_string()
  }
}

///|
fn eval_expr(
  expr : Expr,
  ctx : Value,
  scope : Map[String, Value],
  filters : Array[FilterEntry],
) -> Value raise MoldError {
  match expr {
    Path(segments) => {
      let path_str = segments.join(".")
      resolve_with_scope(ctx, segments, path_str, scope)
    }
    StringLiteral(text) => String(text)
    IntLiteral(value) => Int(value)
    FloatLiteral(value) => Float(value)
    BoolLiteral(value) => Bool(value)
    NullLiteral => Null
    Unary(UnaryOp::Not, inner) =>
      Bool(!is_truthy(eval_expr(inner, ctx, scope, filters)))
    FilterCall(base, name, args) => {
      let value = eval_expr(base, ctx, scope, filters)
      let arg_values : Array[Value] = []
      for arg in args {
        arg_values.push(eval_expr(arg, ctx, scope, filters))
      } nobreak {
        apply_filter(filters, value, name, arg_values)
      }
    }
    Binary(left, BinaryOp::And, right) => {
      let left_value = eval_expr(left, ctx, scope, filters)
      if !is_truthy(left_value) {
        Bool(false)
      } else {
        Bool(is_truthy(eval_expr(right, ctx, scope, filters)))
      }
    }
    Binary(left, BinaryOp::Or, right) => {
      let left_value = eval_expr(left, ctx, scope, filters)
      if is_truthy(left_value) {
        Bool(true)
      } else {
        Bool(is_truthy(eval_expr(right, ctx, scope, filters)))
      }
    }
    Binary(left, op, right) => {
      let left_value = eval_expr(left, ctx, scope, filters)
      let right_value = eval_expr(right, ctx, scope, filters)
      Bool(eval_binary_op(left_value, op, right_value))
    }
  }
}

///|
fn eval_binary_op(
  left : Value,
  op : BinaryOp,
  right : Value,
) -> Bool raise MoldError {
  match op {
    Eq => values_equal(left, right)
    Ne => !values_equal(left, right)
    Lt => compare_values(left, right) < 0
    Le => compare_values(left, right) <= 0
    Gt => compare_values(left, right) > 0
    Ge => compare_values(left, right) >= 0
    And => false
    Or => false
  }
}

///|
fn values_equal(left : Value, right : Value) -> Bool {
  let l = match left {
    Safe(v) => v
    _ => left
  }
  let r = match right {
    Safe(v) => v
    _ => right
  }
  match (l, r) {
    (Null, Null) => true
    (Bool(a), Bool(b)) => a == b
    (Int(a), Int(b)) => a == b
    (Float(a), Float(b)) => a == b
    (Int(a), Float(b)) => a.to_double() == b
    (Float(a), Int(b)) => a == b.to_double()
    (String(a), String(b)) => a == b
    _ => false
  }
}

///|
fn compare_values(left : Value, right : Value) -> Int raise MoldError {
  let l = match left {
    Safe(v) => v
    _ => left
  }
  let r = match right {
    Safe(v) => v
    _ => right
  }
  match (l, r) {
    (Int(a), Int(b)) => compare_ints(a, b)
    (Float(a), Float(b)) => compare_doubles(a, b)
    (Int(a), Float(b)) => compare_doubles(a.to_double(), b)
    (Float(a), Int(b)) => compare_doubles(a, b.to_double())
    (String(a), String(b)) => compare_strings(a, b)
    _ => raise TypeMismatch(("cannot compare values", "comparable"))
  }
}

///|
fn compare_ints(left : Int, right : Int) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

///|
fn compare_doubles(left : Double, right : Double) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

///|
fn compare_strings(left : String, right : String) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

///|
fn is_truthy(value : Value) -> Bool {
  match value {
    Null => false
    Bool(b) => b
    String(s) => s.length() > 0
    Safe(inner) => is_truthy(inner)
    _ => true
  }
}
