///|
fn main {
  let output = try {
    let template = @mold.Template::parse("Hello, {{ name | upper }}!")
    template.render(@mold.object({ "name": @mold.string("MoonBit") }))
  } catch {
    _ => "render failed"
  }
  println(output)
}
