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
    Err(@mold.LexerError((msg, _))) =>
      assert_true(msg.contains("empty interpolation"))
    Ok(_) => fail("expected empty interpolation error")
    _ => fail("unexpected error variant")
  }
}

///|
test "unclosed interpolation raises error" {
  let result = try? @mold.render("Hello, {{ name!", @mold.null())
  match result {
    Err(@mold.LexerError((msg, _))) =>
      assert_true(msg.contains("unclosed interpolation"))
    Ok(_) => fail("expected unclosed interpolation error")
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
