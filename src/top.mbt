///|
pub struct Template {
  source : String
  ast : Array[Node]
}

///|
pub struct Engine {}

///|
pub fn Template::parse(source : String) -> Template raise MoldError {
  let tokens = lex(source)
  let nodes = parse(tokens)
  { source, ast: nodes }
}

///|
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError {
  render_ast(self.ast, ctx, self.source)
}

///|
pub fn Template::source(self : Template) -> String noraise {
  self.source
}

///|
pub fn Engine::new() -> Engine noraise {
  Engine::{  }
}

///|
pub fn Engine::parse(
  self : Engine,
  source : String,
) -> Template raise MoldError {
  let _ = self
  Template::parse(source)
}

///|
pub fn Engine::render(
  self : Engine,
  source : String,
  ctx : Value,
) -> String raise MoldError {
  let _ = self
  Template::parse(source).render(ctx)
}

///|
pub fn render(source : String, ctx : Value) -> String raise MoldError {
  Engine::new().render(source, ctx)
}
