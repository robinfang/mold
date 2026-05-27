# mold

`mold` 是一个面向 MoonBit 生态的轻量模板引擎。

`mold` is a lightweight template engine for the MoonBit ecosystem.

## 仓库链接 / Repository Links

- GitHub: <https://github.com/robinfang/mold>
- GitLink: <https://www.gitlink.org.cn/robinfang/mold>

## 项目简介 / Overview

MoonBit 生态目前缺少一个边界清晰、API 干净、可测试可复用的模板引擎。`mold` 的目标是填补这个空白，提供从模板解析、抽象语法树构建、上下文求值到最终渲染输出的完整链路。

MoonBit still lacks a focused template engine with clean APIs, solid tests, and a reusable runtime model. `mold` aims to fill that gap with a complete pipeline from template parsing and AST construction to context evaluation and final rendering.

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

## API

### 快速渲染 / Quick Render

```moonbit
pub fn render(source : String, ctx : Value) -> String raise MoldError
```

### 模板编译 / Template Compilation

```moonbit
pub fn Template::parse(source : String) -> Template raise MoldError
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError
pub fn Template::source(self : Template) -> String
```

### 引擎 / Engine

```moonbit
pub fn Engine::new() -> Engine
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

## 发布计划 / Publishing Plan

项目会在继续稳定 API、错误定位和表达式能力后发布到 `mooncakes.io`。

The package is intended to be published to `mooncakes.io` after the API and error-reporting surface are stabilized further.

## 开源协议 / License

Apache-2.0
