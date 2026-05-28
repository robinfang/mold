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
test "filter length on array" {
  let output = @mold.render(
    "{{ items | length }}",
    @mold.object({
      "items": @mold.array([
        @mold.string("a"),
        @mold.string("b"),
        @mold.string("c"),
      ]),
    }),
  )
  assert_eq(output, "3")
}

///|
test "filter length on empty array" {
  let output = @mold.render(
    "{{ items | length }}",
    @mold.object({ "items": @mold.array([]) }),
  )
  assert_eq(output, "0")
}

///|
test "filter length on string" {
  let output = @mold.render(
    "{{ text | length }}",
    @mold.object({ "text": @mold.string("hello") }),
  )
  assert_eq(output, "5")
}

///|
test "filter length on null" {
  let output = @mold.render(
    "{{ value | length }}",
    @mold.object({ "value": @mold.null() }),
  )
  assert_eq(output, "0")
}

///|
test "filter length on int raises type mismatch" {
  let result = try? @mold.render(
    "{{ count | length }}",
    @mold.object({ "count": @mold.int(42) }),
  )
  match result {
    Err(@mold.TypeMismatch(_)) => ()
    Ok(_) => fail("expected type mismatch error")
    _ => fail("unexpected error variant")
  }
}
