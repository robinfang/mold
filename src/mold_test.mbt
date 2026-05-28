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
test "render plain text" {
  let output = @mold.render("hello, mold", @mold.null())
  assert_eq(output, "hello, mold")
}

///|
test "template stores source" {
  let template = @mold.Template::parse("sample")
  assert_eq(template.source(), "sample")
}

///|
test "render interpolation" {
  let output = @mold.render(
    "Hello, {{ name }}!",
    @mold.object({ "name": @mold.string("MoonBit") }),
  )
  assert_eq(output, "Hello, MoonBit!")
}

///|
test "render nested interpolation" {
  let output = @mold.render(
    "Hello, {{ user.name }}!",
    @mold.object({ "user": @mold.object({ "name": @mold.string("Alice") }) }),
  )
  assert_eq(output, "Hello, Alice!")
}

///|
test "missing variable raises error" {
  let result = try? @mold.render("Hello, {{ user.name }}!", @mold.object({}))
  match result {
    Err(@mold.MissingVariable(msg)) =>
      assert_true(msg.contains("missing variable"))
    Ok(_) => fail("expected missing variable error")
    _ => fail("unexpected error variant")
  }
}

///|
test "empty interpolation raises error" {
  let result = try? @mold.render("Hello, {{   }}!", @mold.null())
  match result {
    Err(@mold.LexerError((msg, span))) => {
      assert_true(msg.contains("empty interpolation"))
      assert_eq(span.line, 1)
      assert_eq(span.column, 8)
    }
    Ok(_) => fail("expected empty interpolation error")
    _ => fail("unexpected error variant")
  }
}

///|
test "unclosed interpolation raises error" {
  let result = try? @mold.render("Hello\n{{ name!", @mold.null())
  match result {
    Err(@mold.LexerError((msg, span))) => {
      assert_true(msg.contains("unclosed interpolation"))
      assert_eq(span.line, 2)
      assert_eq(span.column, 1)
    }
    Ok(_) => fail("expected unclosed interpolation error")
    _ => fail("unexpected error variant")
  }
}

///|
test "unexpected else carries parser span" {
  let result = try? @mold.render("{% else %}", @mold.null())
  match result {
    Err(@mold.ParserError((msg, span))) => {
      assert_true(msg.contains("unexpected else"))
      assert_eq(span.line, 1)
      assert_eq(span.column, 1)
    }
    Ok(_) => fail("expected unexpected else error")
    _ => fail("unexpected error variant")
  }
}

///|
test "if true renders then branch" {
  let output = @mold.render(
    "{% if active %}yes{% endif %}",
    @mold.object({ "active": @mold.bool(true) }),
  )
  assert_eq(output, "yes")
}

///|
test "if false skips then branch" {
  let output = @mold.render(
    "{% if active %}yes{% endif %}",
    @mold.object({ "active": @mold.bool(false) }),
  )
  assert_eq(output, "")
}

///|
test "if else false renders else branch" {
  let output = @mold.render(
    "{% if active %}yes{% else %}no{% endif %}",
    @mold.object({ "active": @mold.bool(false) }),
  )
  assert_eq(output, "no")
}

///|
test "if with interpolation in body" {
  let output = @mold.render(
    "{% if flag %}Hello, {{ name }}!{% endif %}",
    @mold.object({ "flag": @mold.bool(true), "name": @mold.string("MoonBit") }),
  )
  assert_eq(output, "Hello, MoonBit!")
}

///|
test "nested if uses nearest else" {
  let output = @mold.render(
    "{% if outer %}A{% if inner %}B{% else %}C{% endif %}D{% endif %}",
    @mold.object({ "outer": @mold.bool(true), "inner": @mold.bool(false) }),
  )
  assert_eq(output, "ACD")
}

///|
test "if body can contain nested for loop" {
  let output = @mold.render(
    "{% if show %}{% for item in items %}[{{ item }}]{% endfor %}{% endif %}",
    @mold.object({
      "show": @mold.bool(true),
      "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "[a][b]")
}

///|
test "if supports equality comparison" {
  let output = @mold.render(
    "{% if user.name == \"Alice\" %}yes{% else %}no{% endif %}",
    @mold.object({ "user": @mold.object({ "name": @mold.string("Alice") }) }),
  )
  assert_eq(output, "yes")
}

///|
test "if supports numeric comparison" {
  let output = @mold.render(
    "{% if count >= 3 %}yes{% else %}no{% endif %}",
    @mold.object({ "count": @mold.int(3) }),
  )
  assert_eq(output, "yes")
}

///|
test "comparison works after filter application" {
  let output = @mold.render(
    "{% if name | trim == \"Alice\" %}yes{% else %}no{% endif %}",
    @mold.object({ "name": @mold.string(" Alice ") }),
  )
  assert_eq(output, "yes")
}

///|
test "if supports boolean and" {
  let output = @mold.render(
    "{% if active and ready %}yes{% else %}no{% endif %}",
    @mold.object({ "active": @mold.bool(true), "ready": @mold.bool(true) }),
  )
  assert_eq(output, "yes")
}

///|
test "if supports boolean or" {
  let output = @mold.render(
    "{% if active or backup %}yes{% else %}no{% endif %}",
    @mold.object({ "active": @mold.bool(false), "backup": @mold.bool(true) }),
  )
  assert_eq(output, "yes")
}

///|
test "if supports boolean not" {
  let output = @mold.render(
    "{% if not active %}yes{% else %}no{% endif %}",
    @mold.object({ "active": @mold.bool(false) }),
  )
  assert_eq(output, "yes")
}

///|
test "boolean precedence keeps and tighter than or" {
  let output = @mold.render(
    "{% if active or backup and ready %}yes{% else %}no{% endif %}",
    @mold.object({
      "active": @mold.bool(false),
      "backup": @mold.bool(true),
      "ready": @mold.bool(true),
    }),
  )
  assert_eq(output, "yes")
}

///|
test "parentheses override boolean precedence" {
  let output = @mold.render(
    "{% if (active or backup) and ready %}yes{% else %}no{% endif %}",
    @mold.object({
      "active": @mold.bool(false),
      "backup": @mold.bool(true),
      "ready": @mold.bool(false),
    }),
  )
  assert_eq(output, "no")
}

///|
test "not applies to comparison result" {
  let output = @mold.render(
    "{% if not count == 0 %}yes{% else %}no{% endif %}",
    @mold.object({ "count": @mold.int(1) }),
  )
  assert_eq(output, "yes")
}

///|
test "null is falsy" {
  let output = @mold.render(
    "{% if val %}yes{% else %}no{% endif %}",
    @mold.object({ "val": @mold.null() }),
  )
  assert_eq(output, "no")
}

///|
test "empty string is falsy" {
  let output = @mold.render(
    "{% if val %}yes{% else %}no{% endif %}",
    @mold.object({ "val": @mold.string("") }),
  )
  assert_eq(output, "no")
}

///|
test "bool literal true renders" {
  let output = @mold.render("{{ true }}", @mold.null())
  assert_eq(output, "true")
}

///|
test "bool literal false renders" {
  let output = @mold.render("{{ false }}", @mold.null())
  assert_eq(output, "false")
}

///|
test "bool literal works in if body" {
  let output = @mold.render(
    "{% if true %}yes{% else %}no{% endif %}",
    @mold.null(),
  )
  assert_eq(output, "yes")
}

///|
test "bool literal with not works in if" {
  let output = @mold.render(
    "{% if not false %}yes{% else %}no{% endif %}",
    @mold.null(),
  )
  assert_eq(output, "yes")
}

///|
test "null literal renders empty" {
  let output = @mold.render("{{ null }}", @mold.null())
  assert_eq(output, "")
}

///|
test "null literal is falsy" {
  let output = @mold.render(
    "{% if null %}yes{% else %}no{% endif %}",
    @mold.null(),
  )
  assert_eq(output, "no")
}

///|
test "float literal renders" {
  let output = @mold.render("{{ 3.14 }}", @mold.null())
  assert_eq(output, "3.14")
}

///|
test "negative float literal renders" {
  let output = @mold.render("{{ -0.5 }}", @mold.null())
  assert_eq(output, "-0.5")
}

///|
test "float comparison in if works" {
  let output = @mold.render(
    "{% if price > 3.5 %}high{% else %}low{% endif %}",
    @mold.object({ "price": @mold.float(4.0) }),
  )
  assert_eq(output, "high")
}

///|
test "true equals true in comparison" {
  let output = @mold.render(
    "{% if true == true %}yes{% else %}no{% endif %}",
    @mold.null(),
  )
  assert_eq(output, "yes")
}

///|
test "for loop renders items" {
  let output = @mold.render(
    "{% for item in items %}{{ item }}-{% endfor %}",
    @mold.object({
      "items": @mold.array([
        @mold.string("a"),
        @mold.string("b"),
        @mold.string("c"),
      ]),
    }),
  )
  assert_eq(output, "a-b-c-")
}

///|
test "for empty array produces nothing" {
  let output = @mold.render(
    "{% for item in items %}{{ item }}{% endfor %}",
    @mold.object({ "items": @mold.array([]) }),
  )
  assert_eq(output, "")
}

///|
test "for loop with nested interpolation" {
  let output = @mold.render(
    "{% for user in users %}{{ user.name }},{% endfor %}",
    @mold.object({
      "users": @mold.array([
        @mold.object({ "name": @mold.string("Alice") }),
        @mold.object({ "name": @mold.string("Bob") }),
      ]),
    }),
  )
  assert_eq(output, "Alice,Bob,")
}

///|
test "for loop body can contain nested if" {
  let output = @mold.render(
    "{% for user in users %}{% if user.active %}{{ user.name }}{% else %}skip{% endif %}|{% endfor %}",
    @mold.object({
      "users": @mold.array([
        @mold.object({
          "name": @mold.string("Alice"),
          "active": @mold.bool(true),
        }),
        @mold.object({
          "name": @mold.string("Bob"),
          "active": @mold.bool(false),
        }),
      ]),
    }),
  )
  assert_eq(output, "Alice|skip|")
}

///|
test "nested for loops keep outer scope values" {
  let output = @mold.render(
    "{% for row in rows %}{{ row.name }}:{% for cell in row.items %}{{ cell }}{% endfor %};{% endfor %}",
    @mold.object({
      "rows": @mold.array([
        @mold.object({
          "name": @mold.string("A"),
          "items": @mold.array([@mold.string("1"), @mold.string("2")]),
        }),
        @mold.object({
          "name": @mold.string("B"),
          "items": @mold.array([@mold.string("3")]),
        }),
      ]),
    }),
  )
  assert_eq(output, "A:12;B:3;")
}

///|
test "for non-array raises error" {
  let result = try? @mold.render(
    "{% for item in items %}{{ item }}{% endfor %}",
    @mold.object({ "items": @mold.string("not-an-array") }),
  )
  match result {
    Err(@mold.TypeMismatch(_)) => ()
    Ok(_) => fail("expected type mismatch error")
    _ => fail("unexpected error variant")
  }
}

///|
test "loop.index is 1-based" {
  let output = @mold.render(
    "{% for item in items %}{{ loop.index }}:{{ item }}\n{% endfor %}",
    @mold.object({
      "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "1:a\n2:b\n")
}

///|
test "loop.index0 is 0-based" {
  let output = @mold.render(
    "{% for item in items %}{{ loop.index0 }}:{{ item }}\n{% endfor %}",
    @mold.object({
      "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "0:a\n1:b\n")
}

///|
test "loop.first is true on first iteration" {
  let output = @mold.render(
    "{% for item in items %}{{ loop.first }}-{{ item }}\n{% endfor %}",
    @mold.object({
      "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "true-a\nfalse-b\n")
}

///|
test "loop.last is true on last iteration" {
  let output = @mold.render(
    "{% for item in items %}{{ loop.last }}-{{ item }}\n{% endfor %}",
    @mold.object({
      "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "false-a\ntrue-b\n")
}

///|
test "loop.length is total item count" {
  let output = @mold.render(
    "{% for item in items %}{{ loop.length }}\n{% endfor %}",
    @mold.object({
      "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "2\n2\n")
}

///|
test "loop in nested for has independent scope" {
  let output = @mold.render(
    "{% for outer in outers %}{{ outer }}-{% for inner in inners %}{{ loop.index }}:{{ inner }}{% if not loop.last %}, {% endif %}{% endfor %}\n{% endfor %}",
    @mold.object({
      "outers": @mold.array([@mold.string("X")]),
      "inners": @mold.array([@mold.string("a"), @mold.string("b")]),
    }),
  )
  assert_eq(output, "X-1:a, 2:b\n")
}

///|
test "{%- strips whitespace before block tag" {
  let output = @mold.render(
    "hello   {%- if active %}yes{% endif %}",
    @mold.object({ "active": @mold.bool(true) }),
  )
  assert_eq(output, "helloyes")
}

///|
test "-%} strips whitespace after block tag" {
  let output = @mold.render(
    "{% if active -%}   world{% endif %}",
    @mold.object({ "active": @mold.bool(true) }),
  )
  assert_eq(output, "world")
}

///|
test "{{- strips whitespace before interpolation" {
  let output = @mold.render(
    "hello   {{- name }}!",
    @mold.object({ "name": @mold.string("Alice") }),
  )
  assert_eq(output, "helloAlice!")
}

///|
test "-}} strips whitespace after interpolation" {
  let output = @mold.render(
    "{{ name -}}   world",
    @mold.object({ "name": @mold.string("Hello") }),
  )
  assert_eq(output, "Helloworld")
}

///|
test "combined whitespace control on both sides" {
  let output = @mold.render(
    "hello\n{%- if active -%}\nyes\n{%- endif -%}\nbye",
    @mold.object({ "active": @mold.bool(true) }),
  )
  assert_eq(output, "helloyesbye")
}

///|
test "{# comment #} is removed from output" {
  let output = @mold.render("hello{# this is a comment #}world", @mold.null())
  assert_eq(output, "helloworld")
}

///|
test "comment with interpolation inside is ignored" {
  let output = @mold.render(
    "hello{# {{ name }} #}world",
    @mold.object({ "name": @mold.string("Alice") }),
  )
  assert_eq(output, "helloworld")
}

///|
test "multiline comment is stripped" {
  let output = @mold.render(
    "hello{# line 1\nline 2\nline 3 #}world",
    @mold.null(),
  )
  assert_eq(output, "helloworld")
}

///|
test "autoescape escapes html in interpolation" {
  let engine = @mold.Engine::new().with_autoescape(true)
  let output = engine.render(
    "{{ text }}",
    @mold.object({ "text": @mold.string("<b>bold</b>") }),
  )
  assert_eq(output, "&lt;b&gt;bold&lt;/b&gt;")
}

///|
test "autoescape off leaves html untouched" {
  let output = @mold.render(
    "{{ text }}",
    @mold.object({ "text": @mold.string("<b>bold</b>") }),
  )
  assert_eq(output, "<b>bold</b>")
}

///|
test "safe filter prevents autoescape" {
  let engine = @mold.Engine::new().with_autoescape(true)
  let output = engine.render(
    "{{ text | safe }}",
    @mold.object({ "text": @mold.string("<b>bold</b>") }),
  )
  assert_eq(output, "<b>bold</b>")
}

///|
test "safe filter preserves safety through other filters" {
  let engine = @mold.Engine::new().with_autoescape(true)
  let output = engine.render(
    "{{ text | safe | trim }}",
    @mold.object({ "text": @mold.string("  <b>bold</b>  ") }),
  )
  assert_eq(output, "<b>bold</b>")
}

///|
test "escape filter on safe value still escapes" {
  let engine = @mold.Engine::new().with_autoescape(true)
  let output = engine.render(
    "{{ text | safe | escape }}",
    @mold.object({ "text": @mold.string("<b>bold</b>") }),
  )
  assert_eq(output, "&lt;b&gt;bold&lt;/b&gt;")
}

///|
test "Template.ast returns parsed AST" {
  let template = @mold.Template::parse("hello {{ name }}")
  let nodes = template.ast()
  assert_eq(nodes.length(), 3)
}

///|
test "from_json converts json to Value" {
  let json = @json.parse(
    "{\"name\": \"Alice\", \"age\": 30, \"active\": true, \"scores\": [1, 2, 3]}",
  )
  let ctx = @mold.from_json(json)
  let output = @mold.render("{{ name }} is {{ age }}", ctx)
  assert_eq(output, "Alice is 30")
}

///|
test "from_json handles null and bool" {
  let json = @json.parse("{\"x\": null, \"y\": false, \"z\": true}")
  let ctx = @mold.from_json(json)
  let output = @mold.render("{{ x }}|{{ y }}|{{ z }}", ctx)
  assert_eq(output, "|false|true")
}

///|
test "from_json handles nested objects" {
  let json = @json.parse(
    "{\"user\": {\"name\": \"Bob\", \"scores\": [10, 20]}}",
  )
  let ctx = @mold.from_json(json)
  let output = @mold.render(
    "{{ user.name }}: {{ user.scores | join(\", \") }}", ctx,
  )
  assert_eq(output, "Bob: 10, 20")
}

///|
test "from_map wraps map as Value" {
  let map : Map[String, @mold.Value] = Map::from_array([
    ("x", @mold.string("hi")),
  ])
  let ctx = @mold.from_map(map)
  let output = @mold.render("{{ x }}", ctx)
  assert_eq(output, "hi")
}

///|
test (b : @bench.T) {
  let src = "{% for item in items %}{{ item }}{% endfor %}{% if flag %}yes{% endif %}"
  let ctx_obj = @mold.object({
    "items": @mold.array([@mold.string("a"), @mold.string("b")]),
    "flag": @mold.bool(true),
  })
  b.bench(name="parse_once_render_many", fn() {
    let template = try! @mold.Template::parse(src)
    for _i in 0..<100 {
      b.keep(template.render(ctx_obj) catch { _ => "err" })
    }
  })
  b.bench(name="parse_and_render_each", fn() {
    for _i in 0..<100 {
      b.keep(@mold.render(src, ctx_obj) catch { _ => "err" })
    }
  })
}
