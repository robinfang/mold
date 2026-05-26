///|
pub enum Node {
  Text(String)
  Interpolation(Expr)
  If(Expr, Array[Node], Array[Node])
  For(String, Expr, Array[Node])
}

///|
pub enum Expr {
  Path(Array[String])
  FilterCall(Expr, String, Array[String])
}
