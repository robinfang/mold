///|
pub struct SourceSpan {
  start : Int
  end : Int
} derive(Debug, Eq)

///|
pub suberror MoldError {
  LexerError((String, SourceSpan))
  ParserError((String, SourceSpan))
  MissingVariable(String)
  TypeMismatch((String, String))
} derive(Debug, Eq)
