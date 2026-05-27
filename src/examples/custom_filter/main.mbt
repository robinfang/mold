///|
fn suffix_filter(value : @mold.Value, args : Array[@mold.Value]) -> @mold.Value {
  let suffix = if args.length() > 0 {
    match args[0] {
      @mold.String(text) => text
      _ => ""
    }
  } else {
    ""
  }
  match value {
    @mold.String(text) => @mold.string(text + suffix)
    _ => value
  }
}

///|
fn main {
  let engine = @mold.Engine::new()
  let output = try {
    engine.register_filter("suffix", suffix_filter)
    engine.render(
      "Hello, {{ name | suffix(mark) }}",
      @mold.object({
        "name": @mold.string("MoonBit"),
        "mark": @mold.string("!"),
      }),
    )
  } catch {
    _ => "render failed"
  }
  println(output)
}
