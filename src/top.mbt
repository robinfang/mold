///|
pub type Loader = (String) -> String?

///|
pub struct Template {
  source : String
  ast : Array[Node]
  filters : Array[FilterEntry]
  loader : Loader?
}

///|
pub struct Engine {
  filters : Array[FilterEntry]
  loader : Loader?
}

///|
fn parse_with_filters(
  source : String,
  filters : Array[FilterEntry],
  loader : Loader?,
) -> Template raise MoldError {
  let tokens = lex(source)
  let nodes = parse(tokens)
  { source, ast: nodes, filters, loader }
}

///|
pub fn Template::parse(source : String) -> Template raise MoldError {
  parse_with_filters(source, default_filter_registry(), None)
}

///|
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError {
  render_ast(self.ast, ctx, self.source, self.filters, self.loader)
}

///|
pub fn Template::source(self : Template) -> String noraise {
  self.source
}

///|
pub fn Engine::new() -> Engine noraise {
  Engine::{ filters: default_filter_registry(), loader: None }
}

///|
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine noraise {
  Engine::{ filters: self.filters, loader: Some(loader) }
}

///|
pub fn Engine::register_filter(
  self : Engine,
  name : String,
  filter : Filter,
) -> Unit raise MoldError {
  register_filter_entry(self.filters, name, filter)
}

///|
pub fn Engine::parse(
  self : Engine,
  source : String,
) -> Template raise MoldError {
  parse_with_filters(source, copy_filter_registry(self.filters), self.loader)
}

///|
pub fn Engine::render(
  self : Engine,
  source : String,
  ctx : Value,
) -> String raise MoldError {
  self.parse(source).render(ctx)
}

///|
pub fn render(source : String, ctx : Value) -> String raise MoldError {
  Engine::new().render(source, ctx)
}
