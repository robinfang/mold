///|
pub struct SourceSpan {
  start : Int
  end : Int
  line : Int
  column : Int
} derive(Debug, Eq)

///|
pub suberror MoldError {
  LexerError((String, SourceSpan))
  ParserError((String, SourceSpan))
  UnknownFilter(String)
  DuplicateFilter(String)
  MissingVariable(String)
  TypeMismatch((String, String))
} derive(Debug, Eq)

///|
fn make_span(source : String, start : Int, end : Int) -> SourceSpan noraise {
  let mut line = 1
  let mut column = 1
  for i in 0..<start {
    if source.code_unit_at(i) == '\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
  }
  { start, end, line, column }
}
