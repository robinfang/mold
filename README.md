# mold

`mold` 是一个面向 MoonBit 生态的轻量模板引擎。

## 为什么需要 mold

MoonBit 生态目前缺少一个边界清晰、API 干净、可测试可复用的模板引擎。`mold` 的目标是填补这个空白。

## 当前能力

`mold` 目前支持以下功能：

- 纯文本渲染
- `{{ expr }}` 变量插值，支持点路径访问 (`{{ user.name }}`)
- `{% if expr %}...{% else %}...{% endif %}` 条件分支
- `{% for item in items %}...{% endfor %}` 循环
- 内置过滤器：`upper`、`lower`、`trim`、`default(...)`、`join(...)`
- 结构化错误类型，含源码位置信息
- 预编译：一次 parse，多次 render

## 示例

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

## 首版明确不做

- 模板继承
- 宏系统
- 异步模板
- 自动模板目录扫描
- 布尔与比较表达式 (`and`、`or`、`not`、`==`、`!=`)
- include

## 开发

```text
moon fmt
moon check
moon test
```

运行 benchmark：

```text
moon bench
```

## 示例目录

- `src/examples/hello/`：最小变量插值与过滤器
- `src/examples/report/`：循环、条件分支与嵌套对象
- `src/examples/email/`：更接近真实业务邮件模板的组合用法

## API

### 快速渲染

```moonbit
pub fn render(source : String, ctx : Value) -> String raise MoldError
```

### 模板编译

```moonbit
pub fn Template::parse(source : String) -> Template raise MoldError
pub fn Template::render(self : Template, ctx : Value) -> String raise MoldError
pub fn Template::source(self : Template) -> String
```

### 引擎

```moonbit
pub fn Engine::new() -> Engine
pub fn Engine::parse(self : Engine, source : String) -> Template raise MoldError
pub fn Engine::render(self : Engine, source : String, ctx : Value) -> String raise MoldError
```

### 运行时值模型

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

## 发布计划

首个可用渲染链路落地后，将发布到 `mooncakes.io`。

## 开源协议

Apache-2.0
