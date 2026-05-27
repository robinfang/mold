///|
pub type Loader = (String) -> String?

///|
pub struct Template {
  source : String
  ast : Array[Node]
  filters : Array[FilterEntry]
  loader : Loader?
  autoescape : Bool
}

///|
pub struct Engine {
  filters : Array[FilterEntry]
  loader : Loader?
  autoescape : Bool
}

///|
fn parse_with_filters(
  source : String,
  filters : Array[FilterEntry],
  loader : Loader?,
  autoescape : Bool,
) -> Template raise MoldError {
  let tokens = lex(source)
  let nodes = parse(tokens)
  { source, ast: nodes, filters, loader, autoescape }
}

///|
pub fn Template::parse(source : String) -> Template raise MoldError {
  parse_with_filters(source, default_filter_registry(), None, false)
}

///|
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError {
  render_ast(self.ast, ctx, self.source, self.filters, self.loader, self.autoescape)
}

///|
pub fn Template::source(self : Template) -> String noraise {
  self.source
}

///|
pub fn Template::ast(self : Template) -> Array[Node] noraise {
  self.ast
}

///|
pub fn Engine::new() -> Engine noraise {
  Engine::{ filters: default_filter_registry(), loader: None, autoescape: false }
}

///|
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine noraise {
  Engine::{ filters: self.filters, loader: Some(loader), autoescape: self.autoescape }
}

///|
pub fn Engine::with_autoescape(self : Engine, autoescape : Bool) -> Engine noraise {
  Engine::{ filters: self.filters, loader: self.loader, autoescape }
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
  parse_with_filters(
    source,
    copy_filter_registry(self.filters),
    self.loader,
    self.autoescape,
  )
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
