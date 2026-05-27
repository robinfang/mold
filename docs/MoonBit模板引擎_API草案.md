# MoonBit 模板引擎 API 草案

> 目标：在不依赖反射和复杂宏系统的前提下，提供一套稳定、易讲清、适合比赛首版的 API。

## 一、设计原则

- 首版 API 要少，不要炫技
- 用户第一次看 README 就能写出示例
- 运行时值模型清楚，避免“神奇自动转换”
- 解析 / 编译 / 渲染三层职责分离

## 二、顶层命名建议

以下以包名 `mold` 为例。

## 三、运行时值模型

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

## 四、便捷构造器

```moonbit
pub fn null() -> Value
pub fn bool(v : Bool) -> Value
pub fn int(v : Int) -> Value
pub fn float(v : Double) -> Value
pub fn string(v : String) -> Value
pub fn array(v : Array[Value]) -> Value
pub fn object(v : Map[String, Value]) -> Value
pub fn from_json(json : Json) -> Value
pub fn from_map(map : Map[String, Value]) -> Value
```

目标不是省这几个函数，而是让 README 示例更自然。

## 五、模板对象

```moonbit
pub struct Template

pub fn Template::parse(source : String) -> Template raise Error
pub fn Template::render(self : Template, ctx : Value) -> String raise Error
pub fn Template::ast(self : Template) -> Array[Node]
```

说明：

- `parse` 只做编译，不做渲染
- `render` 只接受统一的 `Value`
- `ast()` 主要用于调试、测试和未来工具化

## 六、一步式 API

```moonbit
pub fn render(source : String, ctx : Value) -> String raise Error
```

适合 README 第一屏示例。

## 七、可扩展引擎对象

```moonbit
pub struct Engine

pub fn Engine::new() -> Engine
pub fn Engine::parse(self : Engine, source : String) -> Template raise Error
pub fn Engine::render(self : Engine, source : String, ctx : Value) -> String raise Error
pub fn Engine::register_filter(
  self : Engine,
  name : String,
  filter : Filter,
) -> Unit raise Error
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine
```

`Loader` 类型定义：

```moonbit
pub type Loader = (String) -> String?
```

当 `Engine` 持有 loader 时，模板中的 `{% include "name" %}` 会通过 loader 查找模板源码并渲染。被包含模板共享父模板的上下文和作用域。

## 八、过滤器接口

```moonbit
pub type Filter = (Value, Array[Value]) -> Value
```

过滤器不声明 raise，由引擎在调用时将错误转换为 `MoldError`。

这样可以支持：

- `{{ name | upper }}`
- `{{ items | join(", ") }}`
- `{{ count | default(0) }}`

## 九、建议内置过滤器

首版建议只有这些：

- `upper`
- `lower`
- `trim`
- `default`
- `join`
- `escape`
- `safe`

这已经足够像“正式模板引擎”了。

## 十、错误模型

```moonbit
pub suberror MoldError {
  LexerError((String, SourceSpan))
  ParserError((String, SourceSpan))
  UnknownFilter(String)
  DuplicateFilter(String)
  MissingVariable(String)
  MissingInclude(String)
  IncludeDepthExceeded
  TypeMismatch((String, String))
} derive(Debug, Eq)
```

其中 `SourceSpan` 建议至少包含：

- start offset
- end offset
- line
- column

## 十一、README 第一屏示例

```moonbit
let tpl = @mold.Template::parse(
  "Hello, {{ user.name }}!\n{% for item in items %}- {{ item }}\n{% endfor %}",
)

let ctx = @mold.object({
  "user": @mold.object({
    "name": @mold.string("Alice"),
  }),
  "items": @mold.array([
    @mold.string("apple"),
    @mold.string("banana"),
  ]),
})

let out = tpl.render(ctx)
```

## 十二、首版语法草案

### 插值

```text
{{ expr }}
```

### 条件

```text
{% if expr %}
  ...
{% else %}
  ...
{% endif %}
```

### 循环

```text
{% for item in items %}
  ...
{% endfor %}
```

### 过滤器

```text
{{ expr | upper }}
{{ expr | join(", ") }}
```

### 包含

```text
{% include "template_name" %}
```

## 十三、刻意不做的 API

首版不要出现：

- `render_file()`
- 自动扫描模板目录
- 模板继承相关 API
- 自动序列化任意 MoonBit struct
- 与 HTTP 框架耦合的 helper

原因：

- 这些都不是模板引擎内核
- 会把范围从“包”做成“框架”

## 十四、结论

这套 API 的优点是：

- 第一屏就能讲清楚
- 比赛首版完全够用
- include 和 custom filter 扩展点已落地
- 未来还能自然扩展到 compile cache / whitespace control / autoescape
