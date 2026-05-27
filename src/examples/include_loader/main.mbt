///|
fn main {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "header" => Some("Report: {{ title }}\n")
      "item" => Some("- {{ item.name }} x {{ item.count }}\n")
      "footer" => Some("Owner: {{ owner }}")
      _ => None
    }
  })
  let template_source =
    #|{% include "header" %}
    #|{% for item in items %}{% include "item" %}{% endfor %}
    #|{% include "footer" %}
  let output = engine.render(
    template_source,
    @mold.object({
      "title": @mold.string("Weekly Stock"),
      "owner": @mold.string("Moon Market"),
      "items": @mold.array([
        @mold.object({ "name": @mold.string("apple"), "count": @mold.int(12) }),
        @mold.object({ "name": @mold.string("banana"), "count": @mold.int(8) }),
      ]),
    }),
  ) catch {
    _ => "render failed"
  }
  println(output)
}
