///|
priv enum BlockToken {
  BlockText(String, Int)
  BlockIf(String, SourceSpan)
  BlockElse(SourceSpan)
  BlockEndIf(SourceSpan)
  BlockFor(String, String, SourceSpan)
  BlockEndFor(SourceSpan)
}

///|
fn lex(source : String) -> Array[Token] raise MoldError {
  let blocks = lex_blocks(source)
  let tokens : Array[Token] = []
  for block in blocks {
    match block {
      BlockText(text, start) =>
        for token in lex_interpolations(text, source, start) {
          tokens.push(token)
        }
      BlockIf(cond, span) => tokens.push(BlockIf(cond, span))
      BlockElse(span) => tokens.push(BlockElse(span))
      BlockEndIf(span) => tokens.push(BlockEndIf(span))
      BlockFor(item, iterable, span) =>
        tokens.push(BlockFor(item, iterable, span))
      BlockEndFor(span) => tokens.push(BlockEndFor(span))
    }
  } nobreak {
    tokens
  }
}

///|
fn lex_blocks(source : String) -> Array[BlockToken] raise MoldError {
  let parts = source.split("{%").collect()
  if parts.length() == 0 {
    return []
  }

  let blocks : Array[BlockToken] = []
  blocks.push(BlockText(parts[0].to_owned(), 0))
  let mut offset = parts[0].length()

  for i = 1; i < parts.length(); i = i + 1 {
    let block_start = offset
    offset = offset + 2
    let segment = parts[i].split("%}").collect()
    if segment.length() < 2 {
      raise LexerError(
        ("unclosed block tag", make_span(source, block_start, source.length())),
      )
    }
    let raw_tag = segment[0].to_owned()
    let block_end = offset + raw_tag.length() + 2
    let span = make_span(source, block_start, block_end)
    let tag = raw_tag.trim().to_owned()
    blocks.push(parse_block_tag(tag, span))
    offset = block_end

    let text = segment[1].to_owned()
    blocks.push(BlockText(text, offset))
    offset = offset + segment[1].length()
    for j = 2; j < segment.length(); j = j + 1 {
      let extra = "%}" + segment[j].to_owned()
      blocks.push(BlockText(extra, offset))
      offset = offset + 2 + segment[j].length()
    }
  } nobreak {
    blocks
  }
}

///|
fn parse_block_tag(
  tag : String,
  span : SourceSpan,
) -> BlockToken raise MoldError {
  let parts = tag.split(" ").collect()
  if parts.length() == 0 {
    raise LexerError(("empty block tag", span))
  }
  let keyword = parts[0].trim().to_owned()
  if keyword == "endif" {
    BlockEndIf(span)
  } else if keyword == "else" {
    BlockElse(span)
  } else if keyword == "endfor" {
    BlockEndFor(span)
  } else if keyword == "if" {
    let cond = extract_condition(tag)
    if cond.length() == 0 {
      raise LexerError(("empty if condition", span))
    }
    BlockIf(cond, span)
  } else if keyword == "for" {
    let (item, iterable) = parse_for_tag(tag, span)
    BlockFor(item, iterable, span)
  } else {
    raise LexerError(("unknown block tag: \{keyword}", span))
  }
}

///|
fn parse_for_tag(
  tag : String,
  span : SourceSpan,
) -> (String, String) raise MoldError {
  let parts = tag.split(" ").collect()
  if parts.length() < 4 {
    raise LexerError(("invalid for tag: \{tag}", span))
  }
  let item = parts[1].trim().to_owned()
  if item.length() == 0 {
    raise LexerError(("missing loop variable in for tag", span))
  }
  let keyword_in = parts[2].trim().to_owned()
  if keyword_in != "in" {
    raise LexerError(("expected 'in' in for tag", span))
  }
  let iterable = extract_for_iterable(tag)
  if iterable.length() == 0 {
    raise LexerError(("missing iterable in for tag", span))
  }
  (item, iterable)
}

///|
fn extract_for_iterable(tag : String) -> String {
  let parts = tag.split(" ").collect()
  if parts.length() < 4 {
    return ""
  }
  let buf = StringBuilder::new(size_hint=tag.length())
  for i = 3; i < parts.length(); i = i + 1 {
    let s = parts[i].trim().to_owned()
    if s.length() > 0 {
      if i > 3 {
        buf.write_char(' ')
      }
      buf.write_string(s)
    }
  }
  buf.to_string()
}

///|
fn extract_condition(tag : String) -> String {
  let parts = tag.split(" ").collect()
  let buf = StringBuilder::new(size_hint=tag.length())
  for i = 1; i < parts.length(); i = i + 1 {
    let s = parts[i].trim().to_owned()
    if s.length() > 0 {
      if i > 1 {
        buf.write_char(' ')
      }
      buf.write_string(s)
    }
  }
  buf.to_string()
}

///|
fn lex_interpolations(
  source : String,
  full_source : String,
  start_offset : Int,
) -> Array[Token] raise MoldError {
  let parts = source.split("{{").collect()
  if parts.length() == 0 {
    return []
  }

  let tokens : Array[Token] = []
  let first_text = parts[0].to_owned()
  tokens.push(
    Text(
      first_text,
      make_span(full_source, start_offset, start_offset + parts[0].length()),
    ),
  )
  let mut offset = start_offset + parts[0].length()

  for i = 1; i < parts.length(); i = i + 1 {
    let interp_start = offset
    offset = offset + 2

    let segment = parts[i].split("}}").collect()
    if segment.length() < 2 {
      raise LexerError(
        (
          "unclosed interpolation tag",
          make_span(full_source, interp_start, start_offset + source.length()),
        ),
      )
    }

    let raw_expr = segment[0].to_owned()
    let interp_end = offset + raw_expr.length() + 2
    let span = make_span(full_source, interp_start, interp_end)
    let expr = raw_expr.trim().to_owned()
    if expr.length() == 0 {
      raise LexerError(("empty interpolation expression", span))
    }
    tokens.push(Interpolation(expr, span))
    offset = interp_end

    let text = segment[1].to_owned()
    tokens.push(
      Text(text, make_span(full_source, offset, offset + segment[1].length())),
    )
    offset = offset + segment[1].length()

    for j = 2; j < segment.length(); j = j + 1 {
      let extra = "}}" + segment[j].to_owned()
      tokens.push(
        Text(
          extra,
          make_span(full_source, offset, offset + 2 + segment[j].length()),
        ),
      )
      offset = offset + 2 + segment[j].length()
    }
  } nobreak {
    tokens
  }
}
