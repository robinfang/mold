///|
fn render_ast(
  nodes : Array[Node],
  ctx : Value,
  source : String,
) -> String raise MoldError {
  render_ast_scoped(nodes, ctx, source, Map::from_array([]))
}

///|
fn render_ast_scoped(
  nodes : Array[Node],
  ctx : Value,
  source : String,
  scope : Map[String, Value],
) -> String raise MoldError {
  let builder = StringBuilder::new(size_hint=source.length())
  for node in nodes {
    match node {
      Text(text) => builder.write_string(text)
      Interpolation(expr) => {
        let value = eval_expr(expr, ctx, scope)
        builder.write_string(value_to_string(value, ""))
      }
      If(cond_expr, then_nodes, else_nodes) => {
        let cond = eval_expr(cond_expr, ctx, scope)
        if is_truthy(cond) {
          builder.write_string(
            render_ast_scoped(then_nodes, ctx, source, scope),
          )
        } else {
          builder.write_string(
            render_ast_scoped(else_nodes, ctx, source, scope),
          )
        }
      }
      For(item_name, iterable_expr, body) => {
        let iterable = eval_expr(iterable_expr, ctx, scope)
        match iterable {
          Array(items) =>
            for item in items {
              let item_scope : Map[String, Value] = Map::from_array([
                (item_name, item),
              ])
              builder.write_string(
                render_ast_scoped(body, ctx, source, item_scope),
              )
            }
          _ => raise TypeMismatch(("cannot iterate", "array"))
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
) -> Value raise MoldError {
  match expr {
    Path(segments) => {
      let path_str = segments.join(".")
      resolve_with_scope(ctx, segments, path_str, scope)
    }
    StringLiteral(text) => String(text)
    IntLiteral(value) => Int(value)
    FilterCall(base, name, args) => {
      let value = eval_expr(base, ctx, scope)
      let arg_values : Array[Value] = []
      for arg in args {
        arg_values.push(eval_expr(arg, ctx, scope))
      } nobreak {
        apply_filter(value, name, arg_values)
      }
    }
  }
}

///|
fn is_truthy(value : Value) -> Bool {
  match value {
    Null => false
    Bool(b) => b
    String(s) => s.length() > 0
    _ => true
  }
}
