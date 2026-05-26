///|
priv enum BlockToken {
  BlockText(String)
  BlockIf(String)
  BlockElse
  BlockEndIf
  BlockFor(String, String)
  BlockEndFor
}

///|
fn lex(source : String) -> Array[Token] raise MoldError {
  let blocks = lex_blocks(source)
  let tokens : Array[Token] = []
  for block in blocks {
    match block {
      BlockText(text) =>
        for token in lex_interpolations(text) {
          tokens.push(token)
        }
      BlockIf(cond) => tokens.push(BlockIf(cond))
      BlockElse => tokens.push(BlockElse)
      BlockEndIf => tokens.push(BlockEndIf)
      BlockFor(item, iterable) => tokens.push(BlockFor(item, iterable))
      BlockEndFor => tokens.push(BlockEndFor)
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
  blocks.push(BlockText(parts[0].to_owned()))

  for i = 1; i < parts.length(); i = i + 1 {
    let segment = parts[i].split("%}").collect()
    if segment.length() < 2 {
      raise LexerError(
        ("unclosed block tag", SourceSpan::{ start: 0, end: source.length() }),
      )
    }
    let raw = segment[0].trim().to_owned()
    blocks.push(parse_block_tag(raw))
    blocks.push(BlockText(segment[1].to_owned()))
    for j = 2; j < segment.length(); j = j + 1 {
      blocks.push(BlockText("%}" + segment[j].to_owned()))
    }
  } nobreak {
    blocks
  }
}

///|
fn parse_block_tag(tag : String) -> BlockToken raise MoldError {
  let parts = tag.split(" ").collect()
  if parts.length() == 0 {
    return BlockEndIf
  }
  let keyword = parts[0].trim().to_owned()
  if keyword == "endif" {
    BlockEndIf
  } else if keyword == "else" {
    BlockElse
  } else if keyword == "endfor" {
    BlockEndFor
  } else if keyword == "if" {
    let cond = extract_condition(tag)
    BlockIf(cond)
  } else if keyword == "for" {
    let (item, iterable) = parse_for_tag(tag)
    BlockFor(item, iterable)
  } else {
    raise LexerError(
      ("unknown block tag: \{keyword}", SourceSpan::{ start: 0, end: 0 }),
    )
  }
}

///|
fn parse_for_tag(tag : String) -> (String, String) raise MoldError {
  let parts = tag.split(" ").collect()
  if parts.length() < 4 {
    raise LexerError(
      ("invalid for tag: \{tag}", SourceSpan::{ start: 0, end: 0 }),
    )
  }
  let item = parts[1].trim().to_owned()
  if item.length() == 0 {
    raise LexerError(
      ("missing loop variable in for tag", SourceSpan::{ start: 0, end: 0 }),
    )
  }
  let keyword_in = parts[2].trim().to_owned()
  if keyword_in != "in" {
    raise LexerError(
      ("expected 'in' in for tag", SourceSpan::{ start: 0, end: 0 }),
    )
  }
  let iterable = extract_for_iterable(tag)
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
    if i > 3 {
      buf.write_char(' ')
    }
    buf.write_string(parts[i].trim().to_owned())
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
fn lex_interpolations(source : String) -> Array[Token] raise MoldError {
  let parts = source.split("{{").collect()
  if parts.length() == 0 {
    return []
  }

  let tokens : Array[Token] = []
  tokens.push(Text(parts[0].to_owned()))
  let mut offset = parts[0].length()

  for i = 1; i < parts.length(); i = i + 1 {
    let interp_start = offset
    offset = offset + 2

    let segment = parts[i].split("}}").collect()
    if segment.length() < 2 {
      let span = SourceSpan::{ start: interp_start, end: source.length() }
      raise LexerError(("unclosed interpolation tag", span))
    }

    let expr = segment[0].trim().to_owned()
    if expr.length() == 0 {
      let span = SourceSpan::{
        start: interp_start,
        end: offset + segment[0].length() + 2,
      }
      raise LexerError(("empty interpolation expression", span))
    }
    tokens.push(Interpolation(expr))
    offset = offset + segment[0].length() + 2

    tokens.push(Text(segment[1].to_owned()))
    offset = offset + segment[1].length()

    for j = 2; j < segment.length(); j = j + 1 {
      tokens.push(Text("}}" + segment[j].to_owned()))
      offset = offset + 2 + segment[j].length()
    }
  } nobreak {
    tokens
  }
}
