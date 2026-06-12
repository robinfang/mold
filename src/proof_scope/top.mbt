///|
pub enum Bindings {
  Empty
  One(Int, Int)
}

///|
pub enum LookupResult {
  Hit(Int)
  Miss
}

///|
pub enum ResolveResult {
  Resolved(Int)
  Missing
}

///|
#proof_pure
pub fn lookup(bindings : Bindings, key : Int) -> LookupResult {
  match bindings {
    Empty => Miss
    One(k, value) => if k == key { Hit(value) } else { Miss }
  }
}

///|
pub fn resolve_head(
  ctx : Bindings,
  local_bindings : Bindings,
  key : Int,
) -> ResolveResult where {
  proof_ensure: result => scope_hit_resolves(local_bindings, key, result),
} {
  match lookup(local_bindings, key) {
    Hit(value) => Resolved(value)
    Miss =>
      match lookup(ctx, key) {
        Hit(value) => Resolved(value)
        Miss => Missing
      }
  }
}

///|
pub fn sample_scope_shadow() -> ResolveResult {
  resolve_head(One(1, 10), One(1, 20), 1)
}

///|
pub fn sample_empty_scope() -> ResolveResult {
  resolve_head(Empty, Empty, 1)
}
