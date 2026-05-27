# mold

`mold` 是一个面向 MoonBit 生态的轻量模板引擎。

`mold` is a lightweight template engine for the MoonBit ecosystem.

## 仓库链接 / Repository Links

- GitHub: <https://github.com/robinfang/mold>
- GitLink: <https://www.gitlink.org.cn/robinfang/mold>

## 安装 / Installation

```text
moon add robinfang/mold
```

## 项目简介 / Overview

MoonBit 生态目前缺少一个边界清晰、API 干净、可测试可复用的模板引擎。`mold` 的目标是填补这个空白，提供从模板解析、抽象语法树构建、上下文求值到最终渲染输出的完整链路。

MoonBit still lacks a focused template engine with clean APIs, solid tests, and a reusable runtime model. `mold` aims to fill that gap with a complete pipeline from template parsing and AST construction to context evaluation and final rendering.

## 快速开始 / Quick Start

```moonbit
let output = @mold.render(
  "Hello, {{ name }}!",
  @mold.object({ "name": @mold.string("World") }),
)
```

## 当前能力 / Current Features

- 纯文本渲染 / plain text rendering
- `{{ expr }}` 变量插值，支持点路径访问 / interpolation with dotted lookup such as `{{ user.name }}`
- `{% if expr %}...{% else %}...{% endif %}` 条件分支 / conditional blocks
- `{% for item in items %}...{% endfor %}` 循环 / array iteration blocks
- 内置过滤器 / built-in filters:
  - `upper`
  - `lower`
  - `trim`
  - `default(...)`
  - `join(...)`
  - `escape`
- 比较与布尔表达式 / comparison and boolean expressions in `if` and interpolation:
  - `== != < <= > >=`
  - `and or not`
  - parentheses grouping such as `(a or b) and c`
- 结构化错误类型与源码位置 / structured errors with source spans
- 预编译模板 / parse once, render many times
- `Engine::register_filter(...)` 自定义过滤器 / custom filter registration via `Engine::register_filter(...)`
- `{% include "template_name" %}` 模板包含 / template inclusion via `{% include "template_name" %}`
- whitespace control / 空白控制: `{%-` / `-%}` and `{{-` / `-}}`
- `{# ... #}` 模板注释 / template comments via `{# ... #}`
- Engine 级 autoescape / engine-level autoescape: `Engine::with_autoescape(true)`
- `| safe` 过滤器阻止自动转义 / `| safe` filter to opt out of autoescaping
- `Template::ast()` 调试访问 / AST debug accessor via `Template::ast()`
- `from_json` / `from_map` JSON 和 Map 到上下文值的转换 / JSON and Map to context Value conversion

## 示例 / Example

```moonbit
let tpl = @mold.Template::parse(
  "Hello, {{ user.name | upper }}!\n\
  {% for item in items %}- {{ item }}\n{% endfor %}",
)

let ctx = @mold.object({
  "user": @mold.object({
    "name": @mold.string("alice"),
  }),
  "items": @mold.array([
    @mold.string("apple"),
    @mold.string("banana"),
  ]),
})

let out = tpl.render(ctx) catch {
  _ => "render failed"
}
```

## 示例目录 / Example Programs

- `src/examples/hello/`
  - 最小变量插值与过滤器 / minimal interpolation and filters
- `src/examples/report/`
  - 循环、条件分支与嵌套对象 / loops, conditionals, and nested objects
- `src/examples/email/`
  - 更接近真实业务邮件模板 / a more realistic email template example

## 模板组合 / Template Composition

通过 `Engine` + `Loader` 组合多个模板。

Compose multiple templates with `Engine` + `Loader`.

```moonbit
let engine = @mold.Engine::new().with_loader(fn(name) {
  match name {
    "header" => Some("Header: {{ title }}\n")
    "footer" => Some("Footer: {{ company }}")
    _ => None
  }
})

let output = engine.render(
  "{% include \"header\" %}\nContent goes here.\n{% include \"footer\" %}",
  @mold.object({
    "title": @mold.string("My Report"),
    "company": @mold.string("ACME Corp"),
  }),
)
```

## HTML 安全 / HTML Safety

默认不启用自动转义，适合通用文本场景。对 HTML 输出可显式启用：

Autoescaping is disabled by default for general text rendering. Enable it explicitly for HTML output:

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)

let output = engine.render(
  "{{ user_input }}",
  @mold.object({ "user_input": @mold.string("<script>alert(1)</script>") }),
)
// 输出 / Output: &lt;script&gt;alert(1)&lt;/script&gt;
```

如需局部输出原始 HTML：`{{ html_content | safe }}`。

To emit raw HTML for specific values, use `{{ html_content | safe }}`.

## API / API Reference

### 快速渲染 / Quick Render

```moonbit
pub fn render(source : String, ctx : Value) -> String raise MoldError
```

### 模板编译 / Template Compilation

```moonbit
pub fn Template::parse(source : String) -> Template raise MoldError
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError
pub fn Template::source(self : Template) -> String
pub fn Template::ast(self : Template) -> Array[Node]
```

### 引擎 / Engine

```moonbit
pub fn Engine::new() -> Engine
pub fn Engine::with_autoescape(self : Engine, autoescape : Bool) -> Engine
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine
pub fn Engine::register_filter(self : Engine, name : String, filter : Filter) -> Unit raise MoldError
pub fn Engine::parse(self : Engine, source : String) -> Template raise MoldError
pub fn Engine::render(self : Engine, source : String, ctx : Value) -> String raise MoldError
```

### 自定义过滤器 / Custom Filters

```moonbit
pub type Filter = (Value, Array[Value]) -> Value
```

### 加载器 / Loader

```moonbit
pub type Loader = (String) -> String?

pub fn Engine::new() -> Engine
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine
```

### 运行时值模型 / Runtime Value Model

```moonbit
pub enum Value {
  Null
  Bool(Bool)
  Int(Int)
  Float(Double)
  String(String)
  Array(Array[Value])
  Object(Map[String, Value])
}

pub fn from_json(json : Json) -> Value
pub fn from_map(map : Map[String, Value]) -> Value
```

### 错误示例 / Error Diagnostics

`mold` 的所有错误都包含位置信息，便于快速定位模板问题。

All `mold` errors include source location information to make template issues easier to diagnose.

模板输入 `{{ missing }}`：

For template input `{{ missing }}`:
```text
Error: MissingVariable("missing variable: missing")
```

模板输入 `{{ name | unknown }}`：

For template input `{{ name | unknown }}`:
```text
Error: UnknownFilter("unknown")
```

模板输入 `{% include "no_such_tpl" %}` 且 loader 找不到：

For template input `{% include "no_such_tpl" %}` when the loader cannot resolve it:
```text
Error: MissingInclude("no_such_tpl")
```

模板输入 `{% if %}`（条件为空）：

For template input `{% if %}` with an empty condition:
```text
Error: LexerError(("empty if condition", SourceSpan{start:0, end:6, line:1, column:1}))
```

在同一个 Engine 上重复注册同名 filter：

When registering the same filter name twice on one `Engine`:
```text
Error: DuplicateFilter("upper")
```

## 开发 / Development

```text
moon fmt
moon check
moon test
```

运行 benchmark / Run benchmarks:

```text
moon bench
```

当前 benchmark 结果表明，`Template::parse(...)` 一次后重复 `render(...)`，明显快于每次都 `parse + render`。

Current benchmarks already show that parsing once and rendering many times is significantly faster than reparsing on every render.

## 当前限制 / Current Limits

- 不支持模板继承 / no template inheritance
- 不支持宏系统 / no macro system
- 不支持异步模板 / no async templates
- 不支持自动模板目录扫描 / no automatic template discovery

## 发布状态 / Release Status

`mold` 已发布到 `mooncakes.io`，当前版本为 `0.1.0`。

`mold` is now published on `mooncakes.io`, and the current version is `0.1.0`.

## 开源协议 / License

Apache-2.0
