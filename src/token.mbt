///|
priv enum Token {
  Text(String)
  Interpolation(String)
  BlockIf(String)
  BlockElse
  BlockEndIf
  BlockFor(String, String)
  BlockEndFor
}
