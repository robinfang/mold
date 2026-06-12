///|
pub type Loader = (String) -> String?

///|
struct CompiledInclude {
  name : String
  source : String
  ast : Array[Node]
}

///|
pub struct Template {
  source : String
  ast : Array[Node]
  filters : Array[FilterEntry]
  loader : Loader?
  includes : Array[CompiledInclude]
  autoescape : Bool
}

///|
pub struct Engine {
  filters : Array[FilterEntry]
  loader : Loader?
  autoescape : Bool
}

///|
fn find_compiled_include(
  includes : Array[CompiledInclude],
  name : String,
) -> CompiledInclude? {
  for entry in includes {
    if entry.name == name {
      return Some(entry)
    }
  }
  None
}

///|
fn compile_named_include(
  name : String,
  loader : Loader,
  depth : Int,
  includes : Array[CompiledInclude],
) -> Unit raise MoldError {
  match find_compiled_include(includes, name) {
    Some(_) => return
    None => ()
  }
  if depth >= 10 {
    raise IncludeDepthExceeded
  }
  let source = match loader(name) {
    Some(source) => source
    None => raise MissingInclude(name)
  }
  let tokens = lex(source)
  let nodes = parse(tokens)
  includes.push({ name, source, ast: nodes })
  compile_include_nodes(nodes, loader, depth + 1, includes)
}

///|
fn compile_include_nodes(
  nodes : Array[Node],
  loader : Loader,
  depth : Int,
  includes : Array[CompiledInclude],
) -> Unit raise MoldError {
  for node in nodes {
    match node {
      Text(_) => ()
      Interpolation(_) => ()
      If(_, then_nodes, else_nodes) => {
        compile_include_nodes(then_nodes, loader, depth, includes)
        compile_include_nodes(else_nodes, loader, depth, includes)
      }
      For(_, _, body) => compile_include_nodes(body, loader, depth, includes)
      Include(name) => compile_named_include(name, loader, depth, includes)
    }
  }
}

///|
fn compile_includes(
  nodes : Array[Node],
  loader : Loader?,
) -> Array[CompiledInclude] raise MoldError {
  let includes : Array[CompiledInclude] = []
  match loader {
    None => ()
    Some(load) => compile_include_nodes(nodes, load, 0, includes)
  }
  includes
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
  let includes = compile_includes(nodes, loader)
  { source, ast: nodes, filters, loader, includes, autoescape }
}

///|
pub fn Template::parse(source : String) -> Template raise MoldError {
  parse_with_filters(source, default_filter_registry(), None, false)
}

///|
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError {
  render_ast(
    self.ast,
    ctx,
    self.source,
    self.filters,
    self.loader,
    self.includes,
    self.autoescape,
  )
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
pub fn Template::inspect(self : Template) -> TemplateInspection noraise {
  inspect_nodes(self.ast)
}

///|
pub fn Engine::new() -> Engine noraise {
  Engine::{
    filters: default_filter_registry(),
    loader: None,
    autoescape: false,
  }
}

///|
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine noraise {
  Engine::{
    filters: self.filters,
    loader: Some(loader),
    autoescape: self.autoescape,
  }
}

///|
pub fn Engine::with_autoescape(
  self : Engine,
  autoescape : Bool,
) -> Engine noraise {
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
pub fn Engine::inspect(
  self : Engine,
  source : String,
) -> TemplateInspection raise MoldError {
  self.parse(source).inspect()
}

///|
pub fn render(source : String, ctx : Value) -> String raise MoldError {
  Engine::new().render(source, ctx)
}

///|
pub fn inspect(source : String) -> TemplateInspection raise MoldError {
  Template::parse(source).inspect()
}
