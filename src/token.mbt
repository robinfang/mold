///|
priv enum Token {
  Text(String, SourceSpan)
  Interpolation(String, SourceSpan)
  BlockIf(String, SourceSpan)
  BlockElse(SourceSpan)
  BlockEndIf(SourceSpan)
  BlockFor(String, String, SourceSpan)
  BlockEndFor(SourceSpan)
}

///|
fn token_span(token : Token) -> SourceSpan noraise {
  match token {
    Text(_, span) => span
    Interpolation(_, span) => span
    BlockIf(_, span) => span
    BlockElse(span) => span
    BlockEndIf(span) => span
    BlockFor(_, _, span) => span
    BlockEndFor(span) => span
  }
}
