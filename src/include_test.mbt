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
  try engine.render("{% include \"missing\" %}", @mold.null()) catch {
    @mold.MissingInclude(name) => assert_eq(name, "missing")
    _ => fail("unexpected error variant")
  } noraise {
    _ => fail("expected missing include error")
  }
}

///|
test "include without loader raises error" {
  try @mold.render("{% include \"header\" %}", @mold.null()) catch {
    @mold.MissingInclude(_) => ()
    _ => fail("unexpected error variant")
  } noraise {
    _ => fail("expected missing include error")
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
test "include exceeding depth limit raises error" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "loop" => Some("{% include \"loop\" %}")
      _ => None
    }
  })
  try engine.render("{% include \"loop\" %}", @mold.null()) catch {
    @mold.IncludeDepthExceeded => ()
    _ => fail("unexpected error variant")
  } noraise {
    _ => fail("expected include depth exceeded error")
  }
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
test "engine parse reuses compiled includes across renders" {
  let mut load_count = 0
  let engine = @mold.Engine::new().with_loader(fn(name) {
    load_count = load_count + 1
    match name {
      "header" => Some("Hi, {{ name }}")
      _ => None
    }
  })
  let template = engine.parse("{% include \"header\" %}")
  let first = template.render(@mold.object({ "name": @mold.string("Alice") }))
  let second = template.render(@mold.object({ "name": @mold.string("Bob") }))
  assert_eq(first, "Hi, Alice")
  assert_eq(second, "Hi, Bob")
  assert_eq(load_count, 1)
}

///|
test "include propagates lexer error from included template" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "broken" => Some("{% if %}")
      _ => None
    }
  })
  try engine.render("{% include \"broken\" %}", @mold.null()) catch {
    @mold.LexerError((msg, _)) =>
      assert_true(msg.contains("empty if condition"))
    _ => fail("unexpected error variant")
  } noraise {
    _ => fail("expected lexer error")
  }
}

///|
test "include respects comments and whitespace control" {
  let engine = @mold.Engine::new().with_loader(fn(name) {
    match name {
      "name_tag" => Some(" {# hidden #}{{- name -}} ")
      _ => None
    }
  })
  let output = engine.render(
    "A{% include \"name_tag\" %}B",
    @mold.object({ "name": @mold.string("X") }),
  )
  assert_eq(output, "AXB")
}
