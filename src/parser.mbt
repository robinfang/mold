///|
fn parse(tokens : Array[Token]) -> Array[Node] raise MoldError {
  let (nodes, _) = parse_nodes(tokens, 0)
  nodes
}

///|
priv enum ExprToken {
  Ident(String)
  StringLiteral(String)
  IntLiteral(Int)
  And
  Or
  Not
  Dot
  Pipe
  LParen
  RParen
  Comma
  EqEq
  BangEq
  Lt
  Le
  Gt
  Ge
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
        nodes.push(Interpolation(parse_expr(expr, span)))
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
        nodes.push(If(parse_expr(cond, block_span), then_nodes, else_nodes))
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
        nodes.push(
          For(item_name, parse_expr(iterable_raw, block_span), body_nodes),
        )
      }
      BlockElse(span) => raise ParserError(("unexpected else", span))
      BlockEndIf(span) => raise ParserError(("unexpected endif", span))
      BlockEndFor(span) => raise ParserError(("unexpected endfor", span))
      BlockInclude(name, _) => {
        nodes.push(Include(name))
        i = i + 1
      }
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
        nodes.push(Interpolation(parse_expr(expr, span)))
        i = i + 1
      }
      BlockElse(_) => break (nodes, i)
      BlockEndIf(_) => break (nodes, i)
      BlockEndFor(_) => break (nodes, i)
      BlockIf(_, _) => break (nodes, i)
      BlockFor(_, _, _) => break (nodes, i)
      BlockInclude(name, _) => {
        nodes.push(Include(name))
        i = i + 1
      }
    }
  } nobreak {
    (nodes, i)
  }
}

///|
fn parse_expr(raw : String, span : SourceSpan) -> Expr raise MoldError {
  let tokens = tokenize_expr(raw, span)
  let (expr, position) = parse_or_tokens(tokens, 0, span)
  if position < tokens.length() {
    raise ParserError(("unexpected token in expression", span))
  }
  expr
}

///|
fn parse_or_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  let (base, next) = parse_and_tokens(tokens, start, span)
  let mut expr = base
  let mut position = next
  while position < tokens.length() {
    if !is_or(tokens[position]) {
      break (expr, position)
    }
    let (right, next_right) = parse_and_tokens(tokens, position + 1, span)
    expr = Binary(expr, BinaryOp::Or, right)
    position = next_right
  } nobreak {
    (expr, position)
  }
}

///|
fn parse_and_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  let (base, next) = parse_not_tokens(tokens, start, span)
  let mut expr = base
  let mut position = next
  while position < tokens.length() {
    if !is_and(tokens[position]) {
      break (expr, position)
    }
    let (right, next_right) = parse_not_tokens(tokens, position + 1, span)
    expr = Binary(expr, BinaryOp::And, right)
    position = next_right
  } nobreak {
    (expr, position)
  }
}

///|
fn parse_not_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  if start < tokens.length() && is_not(tokens[start]) {
    let (expr, next) = if start + 1 < tokens.length() &&
      is_not(tokens[start + 1]) {
      parse_not_tokens(tokens, start + 1, span)
    } else {
      parse_comparison_tokens(tokens, start + 1, span)
    }
    return (Unary(UnaryOp::Not, expr), next)
  }
  parse_comparison_tokens(tokens, start, span)
}

///|
fn parse_comparison_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  let (base, next) = parse_postfix_tokens(tokens, start, span)
  let mut expr = base
  let mut position = next
  while position < tokens.length() {
    match token_to_binary_op(tokens[position]) {
      Some(op) => {
        let (right, next_right) = parse_postfix_tokens(
          tokens,
          position + 1,
          span,
        )
        expr = Binary(expr, op, right)
        position = next_right
      }
      None => break (expr, position)
    }
  } nobreak {
    (expr, position)
  }
}

///|
fn parse_postfix_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  let (base, next) = parse_primary_tokens(tokens, start, span)
  let mut expr = base
  let mut position = next
  while position < tokens.length() {
    match tokens[position] {
      Pipe => {
        let (name, name_pos) = parse_filter_name_token(
          tokens,
          position + 1,
          span,
        )
        let (args, next_pos) = parse_filter_args_tokens(tokens, name_pos, span)
        expr = FilterCall(expr, name, args)
        position = next_pos
      }
      _ => break (expr, position)
    }
  } nobreak {
    (expr, position)
  }
}

///|
fn parse_primary_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  if start >= tokens.length() {
    raise ParserError(("expected expression", span))
  }
  match tokens[start] {
    ExprToken::Ident(_) => parse_path_tokens(tokens, start, span)
    ExprToken::StringLiteral(text) => (StringLiteral(text), start + 1)
    ExprToken::IntLiteral(value) => (IntLiteral(value), start + 1)
    ExprToken::LParen => {
      let (expr, next) = parse_or_tokens(tokens, start + 1, span)
      if next >= tokens.length() || !is_rparen(tokens[next]) {
        raise ParserError(("expected ')' in expression", span))
      }
      (expr, next + 1)
    }
    _ => raise ParserError(("expected expression", span))
  }
}

///|
fn parse_path_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Expr, Int) raise MoldError {
  let segments : Array[String] = []
  let mut position = start
  while position < tokens.length() {
    match tokens[position] {
      ExprToken::Ident(name) => {
        segments.push(name)
        position = position + 1
      }
      _ => raise ParserError(("expected path segment", span))
    }
    if position >= tokens.length() || !is_dot(tokens[position]) {
      break (Path(segments), position)
    }
    position = position + 1
  } nobreak {
    (Path(segments), position)
  }
}

///|
fn parse_filter_name_token(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (String, Int) raise MoldError {
  if start >= tokens.length() {
    raise ParserError(("expected filter name", span))
  }
  match tokens[start] {
    ExprToken::Ident(name) => (name, start + 1)
    _ => raise ParserError(("expected filter name", span))
  }
}

///|
fn parse_filter_args_tokens(
  tokens : Array[ExprToken],
  start : Int,
  span : SourceSpan,
) -> (Array[Expr], Int) raise MoldError {
  if start >= tokens.length() {
    return ([], start)
  }
  match tokens[start] {
    LParen => {
      let args : Array[Expr] = []
      let mut position = start + 1
      if position < tokens.length() && is_rparen(tokens[position]) {
        return (args, position + 1)
      }
      while true {
        let (arg, next) = parse_or_tokens(tokens, position, span)
        args.push(arg)
        position = next
        if position < tokens.length() && is_rparen(tokens[position]) {
          return (args, position + 1)
        }
        if position >= tokens.length() || !is_comma(tokens[position]) {
          raise ParserError(("expected ',' or ')' in filter arguments", span))
        }
        position = position + 1
      } nobreak {
        (args, position)
      }
    }
    _ => ([], start)
  }
}

///|
fn tokenize_expr(
  raw : String,
  span : SourceSpan,
) -> Array[ExprToken] raise MoldError {
  let chars = raw.to_array()
  let tokens : Array[ExprToken] = []
  let mut i = 0
  while i < chars.length() {
    let ch = chars[i]
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      i = i + 1
      continue
    }
    if ch == '"' {
      let (text, next) = read_string_literal(chars, i, span)
      tokens.push(ExprToken::StringLiteral(text))
      i = next
      continue
    }
    if is_int_start(chars, i) {
      let (value, next) = read_int_literal(chars, i)
      tokens.push(ExprToken::IntLiteral(value))
      i = next
      continue
    }
    if is_ident_start(ch) {
      let (name, next) = read_identifier(chars, i)
      match name {
        "and" => tokens.push(And)
        "or" => tokens.push(Or)
        "not" => tokens.push(Not)
        _ => tokens.push(ExprToken::Ident(name))
      }
      i = next
      continue
    }
    if i + 1 < chars.length() {
      let next = chars[i + 1]
      if ch == '=' && next == '=' {
        tokens.push(EqEq)
        i = i + 2
        continue
      }
      if ch == '!' && next == '=' {
        tokens.push(BangEq)
        i = i + 2
        continue
      }
      if ch == '<' && next == '=' {
        tokens.push(Le)
        i = i + 2
        continue
      }
      if ch == '>' && next == '=' {
        tokens.push(Ge)
        i = i + 2
        continue
      }
    }
    match ch {
      '.' => tokens.push(Dot)
      '|' => tokens.push(Pipe)
      '(' => tokens.push(LParen)
      ')' => tokens.push(RParen)
      ',' => tokens.push(Comma)
      '<' => tokens.push(Lt)
      '>' => tokens.push(Gt)
      _ => raise ParserError(("invalid expression token", span))
    }
    i = i + 1
  } nobreak {
    tokens
  }
}

///|
fn read_string_literal(
  chars : Array[Char],
  start : Int,
  span : SourceSpan,
) -> (String, Int) raise MoldError {
  let buf = StringBuilder::new()
  let mut i = start + 1
  while i < chars.length() {
    let ch = chars[i]
    if ch == '"' {
      return (buf.to_string(), i + 1)
    }
    buf.write_char(ch)
    i = i + 1
  }
  raise ParserError(("unclosed string literal", span))
}

///|
fn read_int_literal(chars : Array[Char], start : Int) -> (Int, Int) {
  let mut i = start
  let mut negative = false
  if chars[i] == '-' {
    negative = true
    i = i + 1
  }
  let mut value = 0
  while i < chars.length() {
    let ch = chars[i]
    if ch >= '0' && ch <= '9' {
      value = value * 10 + (ch.to_int() - '0'.to_int())
      i = i + 1
    } else {
      return (if negative { -value } else { value }, i)
    }
  } nobreak {
    (if negative { -value } else { value }, i)
  }
}

///|
fn read_identifier(chars : Array[Char], start : Int) -> (String, Int) {
  let buf = StringBuilder::new()
  let mut i = start
  while i < chars.length() && is_ident_continue(chars[i]) {
    buf.write_char(chars[i])
    i = i + 1
  } nobreak {
    (buf.to_string(), i)
  }
}

///|
fn is_ident_start(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

///|
fn is_ident_continue(ch : Char) -> Bool {
  is_ident_start(ch) || (ch >= '0' && ch <= '9')
}

///|
fn is_int_start(chars : Array[Char], index : Int) -> Bool {
  let ch = chars[index]
  if ch >= '0' && ch <= '9' {
    return true
  }
  ch == '-' &&
  index + 1 < chars.length() &&
  chars[index + 1] >= '0' &&
  chars[index + 1] <= '9'
}

///|
fn is_rparen(token : ExprToken) -> Bool {
  match token {
    RParen => true
    _ => false
  }
}

///|
fn is_comma(token : ExprToken) -> Bool {
  match token {
    Comma => true
    _ => false
  }
}

///|
fn is_dot(token : ExprToken) -> Bool {
  match token {
    Dot => true
    _ => false
  }
}

///|
fn is_and(token : ExprToken) -> Bool {
  match token {
    And => true
    _ => false
  }
}

///|
fn is_or(token : ExprToken) -> Bool {
  match token {
    Or => true
    _ => false
  }
}

///|
fn is_not(token : ExprToken) -> Bool {
  match token {
    Not => true
    _ => false
  }
}

///|
fn token_to_binary_op(token : ExprToken) -> BinaryOp? {
  match token {
    EqEq => Some(BinaryOp::Eq)
    BangEq => Some(BinaryOp::Ne)
    Lt => Some(BinaryOp::Lt)
    Le => Some(BinaryOp::Le)
    Gt => Some(BinaryOp::Gt)
    Ge => Some(BinaryOp::Ge)
    _ => None
  }
}
