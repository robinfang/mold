///|
fn main {
  let head =
    #|<!DOCTYPE html>
    #|<html lang="zh-CN">
    #|<head><meta charset="UTF-8">
    #|<title>{{ title }} - {{ site_name }}</title></head>
    #|<body><header><h1>{{ site_name }}</h1>
    #|{% include "nav" %}</header><main>
  let nav =
    #|<nav><a href="/">Home</a> | <a href="/archive">Archive</a></nav>
  let footer =
    #|</main><footer><hr><p>© 2026 {{ site_name }}</p></footer>
    #|</body></html>
  let post_body =
    #|{% include "head" %}
    #|<article><h2>{{ title }}</h2>
    #|<time>{{ date }}</time>
    #|{% if draft %}<p><em>draft</em></p>{% endif %}
    #|<div>{{ body | safe }}</div>
    #|</article>
    #|{% include "footer" %}
  let archive_body =
    #|{% include "head" %}
    #|<h2>Posts</h2>
    #|{% for post in posts %}
    #|{% if not post.draft %}
    #|  <article><h3>{{ post.title }}</h3>
    #|  <time>{{ post.date }}</time>
    #|  <p>{{ post.summary }}</p>
    #|  </article>
    #|{% endif %}
    #|{% endfor %}
    #|{% include "footer" %}

  let engine = @mold.Engine::new()
    .with_autoescape(true)
    .with_loader(fn(name) {
      match name {
        "head" => Some(head)
        "nav" => Some(nav)
        "footer" => Some(footer)
        "post" => Some(post_body)
        "archive" => Some(archive_body)
        _ => None
      }
    })

  let posts = @mold.array([
    @mold.object({
      "title": @mold.string("Hello, mold"),
      "date": @mold.string("2026-05-28"),
      "draft": @mold.bool(false),
      "body": @mold.string("<p>Hello world</p>"),
      "summary": @mold.string("First post."),
    }),
    @mold.object({
      "title": @mold.string("template composition"),
      "date": @mold.string("2026-05-27"),
      "draft": @mold.bool(false),
      "body": @mold.string("<p>Compose</p>"),
      "summary": @mold.string("How to compose."),
    }),
    @mold.object({
      "title": @mold.string("Draft"),
      "date": @mold.string("2026-05-29"),
      "draft": @mold.bool(true),
      "body": @mold.string("<p>Hidden</p>"),
      "summary": @mold.string("Draft."),
    }),
  ])

  let output = try {
    let post_tpl = engine.parse("{% include \"post\" %}")
    let archive_tpl = engine.parse("{% include \"archive\" %}")

    let builder = StringBuilder::new(size_hint=3000)

    builder.write_string(
      post_tpl.render(
        @mold.object({
          "site_name": @mold.string("My Site"),
          "title": @mold.string("Hello, mold"),
          "date": @mold.string("2026-05-28"),
          "draft": @mold.bool(false),
          "body": @mold.string("<p>Hello world</p>"),
        }),
      ),
    )

    builder.write_string("\n")

    builder.write_string(
      archive_tpl.render(
        @mold.object({
          "site_name": @mold.string("My Site"),
          "title": @mold.string("Posts"),
          "posts": posts,
        }),
      ),
    )

    builder.to_string()
  } catch {
    _ => "render failed"
  }
  println(output)
}
