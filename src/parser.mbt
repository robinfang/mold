///|
fn parse(tokens : Array[Token]) -> Array[Node] raise MoldError {
  let (nodes, _) = parse_nodes(tokens, 0)
  nodes
}

///|
fn parse_nodes(
  tokens : Array[Token],
  start : Int,
) -> (Array[Node], Int) raise MoldError {
  let nodes : Array[Node] = []
  let mut i = start
  while i < tokens.length() {
    match tokens[i] {
      Text(text) => {
        nodes.push(Text(text))
        i = i + 1
      }
      Interpolation(expr) => {
        nodes.push(parse_expr(expr))
        i = i + 1
      }
      BlockIf(cond) => {
        i = i + 1
        let (then_nodes, next) = parse_nodes_until(tokens, i)
        i = next
        let mut else_nodes : Array[Node] = []
        if i < tokens.length() {
          match tokens[i] {
            BlockElse => {
              i = i + 1
              let (nodes_e, next2) = parse_nodes_until(tokens, i)
              else_nodes = nodes_e
              i = next2
            }
            BlockEndIf => else_nodes = []
            _ =>
              raise ParserError(
                ("expected endif or else", SourceSpan::{ start: 0, end: 0 }),
              )
          }
        } else {
          raise ParserError(
            ("expected endif", SourceSpan::{ start: 0, end: 0 }),
          )
        }
        if i < tokens.length() {
          match tokens[i] {
            BlockEndIf => i = i + 1
            _ =>
              raise ParserError(
                ("expected endif", SourceSpan::{ start: 0, end: 0 }),
              )
          }
        }
        let node = parse_expr(cond)
        match node {
          Interpolation(expr) => nodes.push(If(expr, then_nodes, else_nodes))
          _ => nodes.push(If(Path([]), then_nodes, else_nodes))
        }
      }
      BlockFor(item_name, iterable_raw) => {
        i = i + 1
        let (body_nodes, next) = parse_nodes_until(tokens, i)
        i = next
        if i < tokens.length() {
          match tokens[i] {
            BlockEndFor => i = i + 1
            _ =>
              raise ParserError(
                ("expected endfor", SourceSpan::{ start: 0, end: 0 }),
              )
          }
        } else {
          raise ParserError(
            ("expected endfor", SourceSpan::{ start: 0, end: 0 }),
          )
        }
        let iterable_node = parse_expr(iterable_raw)
        match iterable_node {
          Interpolation(expr) => nodes.push(For(item_name, expr, body_nodes))
          _ => nodes.push(For(item_name, Path([]), body_nodes))
        }
      }
      BlockElse =>
        raise ParserError(("unexpected else", SourceSpan::{ start: 0, end: 0 }))
      BlockEndIf =>
        raise ParserError(
          ("unexpected endif", SourceSpan::{ start: 0, end: 0 }),
        )
      BlockEndFor =>
        raise ParserError(
          ("unexpected endfor", SourceSpan::{ start: 0, end: 0 }),
        )
    }
  } nobreak {
    (nodes, i)
  }
}

///|
fn parse_nodes_until(
  tokens : Array[Token],
  start : Int,
) -> (Array[Node], Int) raise MoldError {
  let nodes : Array[Node] = []
  let mut i = start
  while i < tokens.length() {
    match tokens[i] {
      Text(text) => {
        nodes.push(Text(text))
        i = i + 1
      }
      Interpolation(expr) => {
        nodes.push(parse_expr(expr))
        i = i + 1
      }
      BlockElse => break (nodes, i)
      BlockEndIf => break (nodes, i)
      BlockEndFor => break (nodes, i)
      BlockIf(_) => break (nodes, i)
      BlockFor(_, _) => break (nodes, i)
    }
  } nobreak {
    (nodes, i)
  }
}

///|
fn parse_expr(raw : String) -> Node raise MoldError {
  let parts = raw.split("|").collect()
  let base = parse_path(parts[0].trim().to_owned())
  let mut expr : Expr = base
  for i = 1; i < parts.length(); i = i + 1 {
    let filter_raw = parts[i].trim().to_owned()
    let (name, args) = parse_filter_call(filter_raw)
    expr = FilterCall(expr, name, args)
  } nobreak {
    Interpolation(expr)
  }
}

///|
fn parse_path(raw : String) -> Expr raise MoldError {
  let segments : Array[String] = []
  for part in raw.split(".") {
    let name = part.trim().to_owned()
    if name.length() == 0 {
      raise ParserError(
        ("invalid path: \{raw}", SourceSpan::{ start: 0, end: 0 }),
      )
    }
    segments.push(name)
  }
  Path(segments)
}

///|
fn parse_filter_call(raw : String) -> (String, Array[String]) noraise {
  let paren_parts = raw.split("(").collect()
  if paren_parts.length() < 2 {
    return (raw, [])
  }
  let name = paren_parts[0].trim().to_owned()
  let args_with_paren = StringBuilder::new(size_hint=raw.length())
  for i = 1; i < paren_parts.length(); i = i + 1 {
    if i > 1 {
      args_with_paren.write_char('(')
    }
    args_with_paren.write_string(paren_parts[i].to_owned())
  }
  let args_str = args_with_paren.to_string()
  let rpar_parts = args_str.split(")").collect()
  let args_raw = StringBuilder::new(size_hint=args_str.length())
  let last = rpar_parts.length()
  for j = 0; j < last; j = j + 1 {
    if j == last - 1 {
      continue
    }
    if j > 0 {
      args_raw.write_char(')')
    }
    args_raw.write_string(rpar_parts[j].to_owned())
  }
  let stripped = args_raw.to_string().trim().to_owned()
  let args : Array[String] = if stripped.length() == 0 {
    []
  } else {
    [stripped]
  }
  (name, args)
}
