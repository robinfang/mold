///|
fn main {
  let output = try {
    let json = @json.parse(
      "{\"project\": \"mold\", \"active\": true, \"tags\": [\"moonbit\", \"template\"]}",
    )
    let ctx = @mold.from_json(json)
    @mold.render(
      "{{ project }} (active={{ active }}) -> {{ tags | join(\", \") }}", ctx,
    )
  } catch {
    _ => "render failed"
  }
  println(output)
}
