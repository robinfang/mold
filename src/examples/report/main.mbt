///|
fn main {
  let template_source =
    #|Weekly Inventory Report
    #|=======================
    #|
    #|Store: {{ store.name }}
    #|Manager: {{ store.manager | upper }}
    #|
    #|{% if active %}Status: Active{% else %}Status: Paused{% endif %}
    #|
    #|Items
    #|-----
    #|{% for item in items %}- {{ item.name | upper }} x {{ item.count }} @ ${{ item.price }}
    #|{% endfor %}
    #|Total items: {{ total }}
  let output = try {
    let template = @mold.Template::parse(template_source)
    template.render(
      @mold.object({
        "items": @mold.array([
          @mold.object({
            "name": @mold.string("apple"),
            "count": @mold.int(12),
            "price": @mold.int(3),
          }),
          @mold.object({
            "name": @mold.string("banana"),
            "count": @mold.int(8),
            "price": @mold.int(2),
          }),
        ]),
        "total": @mold.int(2),
        "active": @mold.bool(true),
        "store": @mold.object({
          "name": @mold.string("Moon Market"),
          "manager": @mold.string("robin"),
        }),
      }),
    )
  } catch {
    _ => "render failed"
  }
  println(output)
}
