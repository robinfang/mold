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
test "filter upper" {
  let output = @mold.render(
    "{{ name | upper }}",
    @mold.object({ "name": @mold.string("hello") }),
  )
  assert_eq(output, "HELLO")
}

///|
test "filter lower" {
  let output = @mold.render(
    "{{ name | lower }}",
    @mold.object({ "name": @mold.string("HELLO") }),
  )
  assert_eq(output, "hello")
}

///|
test "filter trim" {
  let output = @mold.render(
    "{{ name | trim }}",
    @mold.object({ "name": @mold.string("  hello  ") }),
  )
  assert_eq(output, "hello")
}

///|
test "filter default on null" {
  let output = @mold.render(
    "{{ name | default(\"N/A\") }}",
    @mold.object({ "name": @mold.null() }),
  )
  assert_eq(output, "N/A")
}

///|
test "filter default with int literal" {
  let output = @mold.render(
    "{{ count | default(0) }}",
    @mold.object({ "count": @mold.null() }),
  )
  assert_eq(output, "0")
}

///|
test "filter default with path arg" {
  let output = @mold.render(
    "{{ name | default(fallback) }}",
    @mold.object({ "name": @mold.null(), "fallback": @mold.string("guest") }),
  )
  assert_eq(output, "guest")
}

///|
test "filter join" {
  let output = @mold.render(
    "{{ items | join(\", \") }}",
    @mold.object({
      "items": @mold.array([
        @mold.string("a"),
        @mold.string("b"),
        @mold.string("c"),
      ]),
    }),
  )
  assert_eq(output, "a, b, c")
}

///|
test "filter join with path arg" {
  let output = @mold.render(
    "{{ items | join(separator) }}",
    @mold.object({
      "items": @mold.array([
        @mold.string("a"),
        @mold.string("b"),
        @mold.string("c"),
      ]),
      "separator": @mold.string(" / "),
    }),
  )
  assert_eq(output, "a / b / c")
}

///|
test "filter escape html characters" {
  let output = @mold.render(
    "{{ text | escape }}",
    @mold.object({
      "text": @mold.string("<div class=\"x\">Tom & 'Jerry'</div>"),
    }),
  )
  assert_eq(
    output, "&lt;div class=&quot;x&quot;&gt;Tom &amp; &#39;Jerry&#39;&lt;/div&gt;",
  )
}

///|
test "filter escape supports scalar values" {
  let output = @mold.render(
    "{{ count | escape }}|{{ empty | escape }}",
    @mold.object({ "count": @mold.int(7), "empty": @mold.null() }),
  )
  assert_eq(output, "7|")
}

///|
test "filter escape rejects arrays" {
  let result = try? @mold.render(
    "{{ items | escape }}",
    @mold.object({ "items": @mold.array([@mold.string("a")]) }),
  )
  match result {
    Err(@mold.TypeMismatch(_)) => ()
    Ok(_) => fail("expected type mismatch error")
    _ => fail("unexpected error variant")
  }
}

///|
test "engine custom filter registration" {
  let engine = @mold.Engine::new()
  engine.register_filter("suffix", suffix_filter)
  let output = engine.render(
    "{{ name | suffix(suffix) }}",
    @mold.object({ "name": @mold.string("hello"), "suffix": @mold.string("!") }),
  )
  assert_eq(output, "hello!")
}

///|
test "cannot override built-in filter" {
  let engine = @mold.Engine::new()
  let result = try? engine.register_filter("upper", suffix_filter)
  match result {
    Err(@mold.DuplicateFilter(name)) => assert_eq(name, "upper")
    Ok(_) => fail("expected duplicate filter error")
    _ => fail("unexpected error variant")
  }
}

///|
test "cannot register duplicate custom filter" {
  let engine = @mold.Engine::new()
  engine.register_filter("suffix", suffix_filter)
  let result = try? engine.register_filter("suffix", suffix_filter)
  match result {
    Err(@mold.DuplicateFilter(name)) => assert_eq(name, "suffix")
    Ok(_) => fail("expected duplicate filter error")
    _ => fail("unexpected error variant")
  }
}

///|
test "unknown filter raises dedicated error" {
  let result = try? @mold.render(
    "{{ name | missing }}",
    @mold.object({ "name": @mold.string("hello") }),
  )
  match result {
    Err(@mold.UnknownFilter(name)) => assert_eq(name, "missing")
    Ok(_) => fail("expected unknown filter error")
    _ => fail("unexpected error variant")
  }
}

///|
test "include renders included template" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "header" => Some("Header: {{ title }}")
      _ => None
    }
  })
  let output = engine.render(
    "{% include \"header\" %}\nBody",
    @mold.object({ "title": @mold.string("My Page") }),
  )
  assert_eq(output, "Header: My Page\nBody")
}

///|
test "include shares parent context" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "item" => Some("- {{ item.name }}")
      _ => None
    }
  })
  let output = engine.render(
    "{% for item in items %}{% include \"item\" %}\n{% endfor %}",
    @mold.object({
      "items": @mold.array([
        @mold.object({ "name": @mold.string("a") }),
        @mold.object({ "name": @mold.string("b") }),
      ]),
    }),
  )
  assert_eq(output, "- a\n- b\n")
}

///|
test "include missing template raises error" {
  let engine = @mold.Engine::new().with_loader(fn(_name) { None })
  let result = try? engine.render("{% include \"missing\" %}", @mold.null())
  match result {
    Err(@mold.MissingInclude(name)) => assert_eq(name, "missing")
    Ok(_) => fail("expected missing include error")
    _ => fail("unexpected error variant")
  }
}

///|
test "include without loader raises error" {
  let result = try? @mold.render("{% include \"header\" %}", @mold.null())
  match result {
    Err(@mold.MissingInclude(_)) => ()
    Ok(_) => fail("expected missing include error")
    _ => fail("unexpected error variant")
  }
}

///|
test "nested include within depth limit" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "outer" => Some("outer[{% include \"inner\" %}]")
      "inner" => Some("inner")
      _ => None
    }
  })
  let output = engine.render("{% include \"outer\" %}", @mold.null())
  assert_eq(output, "outer[inner]")
}

///|
test "include preserves filters of parent engine" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "greeting" => Some("Hi, {{ name | upper }}")
      _ => None
    }
  })
  let output = engine.render(
    "{% include \"greeting\" %}",
    @mold.object({ "name": @mold.string("alice") }),
  )
  assert_eq(output, "Hi, ALICE")
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
  let output = @mold.render(
    "hello{# this is a comment #}world",
    @mold.null(),
  )
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
