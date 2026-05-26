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
      Text(text, _) => {
        nodes.push(Text(text))
        i = i + 1
      }
      Interpolation(expr, span) => {
        nodes.push(parse_expr(expr, span))
        i = i + 1
      }
      BlockIf(cond, block_span) => {
        i = i + 1
        let (then_nodes, next) = parse_nodes_until(tokens, i)
        i = next
        let mut else_nodes : Array[Node] = []
        if i < tokens.length() {
          match tokens[i] {
            BlockElse(_) => {
              i = i + 1
              let (nodes_e, next2) = parse_nodes_until(tokens, i)
              else_nodes = nodes_e
              i = next2
            }
            BlockEndIf(_) => else_nodes = []
            _ =>
              raise ParserError(
                ("expected endif or else", token_span(tokens[i])),
              )
          }
        } else {
          raise ParserError(("expected endif", block_span))
        }
        if i < tokens.length() {
          match tokens[i] {
            BlockEndIf(_) => i = i + 1
            _ => raise ParserError(("expected endif", token_span(tokens[i])))
          }
        }
        let node = parse_expr(cond, block_span)
        match node {
          Interpolation(expr) => nodes.push(If(expr, then_nodes, else_nodes))
          _ => nodes.push(If(Path([]), then_nodes, else_nodes))
        }
      }
      BlockFor(item_name, iterable_raw, block_span) => {
        i = i + 1
        let (body_nodes, next) = parse_nodes_until(tokens, i)
        i = next
        if i < tokens.length() {
          match tokens[i] {
            BlockEndFor(_) => i = i + 1
            _ => raise ParserError(("expected endfor", token_span(tokens[i])))
          }
        } else {
          raise ParserError(("expected endfor", block_span))
        }
        let iterable_node = parse_expr(iterable_raw, block_span)
        match iterable_node {
          Interpolation(expr) => nodes.push(For(item_name, expr, body_nodes))
          _ => nodes.push(For(item_name, Path([]), body_nodes))
        }
      }
      BlockElse(span) => raise ParserError(("unexpected else", span))
      BlockEndIf(span) => raise ParserError(("unexpected endif", span))
      BlockEndFor(span) => raise ParserError(("unexpected endfor", span))
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
      Text(text, _) => {
        nodes.push(Text(text))
        i = i + 1
      }
      Interpolation(expr, span) => {
        nodes.push(parse_expr(expr, span))
        i = i + 1
      }
      BlockElse(_) => break (nodes, i)
      BlockEndIf(_) => break (nodes, i)
      BlockEndFor(_) => break (nodes, i)
      BlockIf(_, _) => break (nodes, i)
      BlockFor(_, _, _) => break (nodes, i)
    }
  } nobreak {
    (nodes, i)
  }
}

///|
fn parse_expr(raw : String, span : SourceSpan) -> Node raise MoldError {
  let parts = raw.split("|").collect()
  let base = parse_path(parts[0].trim().to_owned(), span)
  let mut expr : Expr = base
  for i = 1; i < parts.length(); i = i + 1 {
    let filter_raw = parts[i].trim().to_owned()
    let (name, args) = parse_filter_call(filter_raw, span)
    expr = FilterCall(expr, name, args)
  } nobreak {
    Interpolation(expr)
  }
}

///|
fn parse_path(raw : String, span : SourceSpan) -> Expr raise MoldError {
  let segments : Array[String] = []
  for part in raw.split(".") {
    let name = part.trim().to_owned()
    if name.length() == 0 {
      raise ParserError(("invalid path: \{raw}", span))
    }
    segments.push(name)
  }
  Path(segments)
}

///|
fn parse_filter_call(
  raw : String,
  span : SourceSpan,
) -> (String, Array[Expr]) raise MoldError {
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
  if rpar_parts.length() < 2 {
    raise ParserError(("unclosed filter arguments: \{raw}", span))
  }
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
  let args : Array[Expr] = if stripped.length() == 0 {
    []
  } else {
    [parse_filter_arg(stripped, span)]
  }
  (name, args)
}

///|
fn parse_filter_arg(raw : String, span : SourceSpan) -> Expr raise MoldError {
  let trimmed = raw.trim().to_owned()
  if is_quoted_string(trimmed) {
    return StringLiteral(quoted_string_value(trimmed))
  }
  match try_parse_int_literal(trimmed) {
    Some(value) => IntLiteral(value)
    None => parse_path(trimmed, span)
  }
}

///|
fn is_quoted_string(raw : String) -> Bool {
  raw.length() >= 2 &&
  raw.code_unit_at(0) == '"' &&
  raw.code_unit_at(raw.length() - 1) == '"'
}

///|
fn quoted_string_value(raw : String) -> String {
  let parts = raw.split("\"").collect()
  if parts.length() > 1 {
    parts[1].to_owned()
  } else {
    ""
  }
}

///|
fn try_parse_int_literal(raw : String) -> Int? {
  let mut negative = false
  let mut started = false
  let mut has_digit = false
  let mut value = 0
  for ch in raw {
    if !started && ch == '-' {
      negative = true
      started = true
      continue
    }
    started = true
    if ch < '0' || ch > '9' {
      return None
    }
    has_digit = true
    value = value * 10 + (ch.to_int() - '0'.to_int())
  }
  if !has_digit {
    return None
  }
  Some(if negative { -value } else { value })
}
