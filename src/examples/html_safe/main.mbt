///|
fn main {
  let engine = @mold.Engine::new().with_autoescape(true)
  let template_source =
    #|<section>
    #|  <h1>{{ title }}</h1>
    #|  <div>{{ body }}</div>
    #|  <div>{{ trusted_html | safe }}</div>
    #|</section>
  let output = engine.render(
    template_source,
    @mold.object({
      "title": @mold.string("Release Notes"),
      "body": @mold.string("<strong>escaped</strong>"),
      "trusted_html": @mold.string("<em>kept</em>"),
    }),
  ) catch {
    _ => "render failed"
  }
  println(output)
}
