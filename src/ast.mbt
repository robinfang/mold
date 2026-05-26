///|
pub enum Node {
  Text(String)
  Interpolation(Expr)
  If(Expr, Array[Node], Array[Node])
  For(String, Expr, Array[Node])
}

///|
pub enum BinaryOp {
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  And
  Or
}

///|
pub enum UnaryOp {
  Not
}

///|
pub enum Expr {
  Path(Array[String])
  StringLiteral(String)
  IntLiteral(Int)
  FilterCall(Expr, String, Array[Expr])
  Binary(Expr, BinaryOp, Expr)
  Unary(UnaryOp, Expr)
}
