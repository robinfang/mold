# 快速开始

这篇文档只做一件事：让第一次接触 `mold` 的用户，在最短路径内跑通安装、最小模板和三种推荐使用方式。

如果你还不确定整个文档怎么读，先回到 [`index.md`](index.md) 看总览；如果你已经准备开始写模板，这一篇可以直接往下读。

## 本文结构

1. 先安装并运行最小模板
2. 再理解三种推荐使用路径
3. 最后知道 examples 在哪里、上下文值模型长什么样
4. 需要进阶能力时，知道该跳到哪篇专题文档

## 安装

```text
moon add robinfang/mold
```

## 第一个模板

```moonbit
let output = @mold.render(
  "Hello, {{ name }}!",
  @mold.object({ "name": @mold.string("MoonBit") }),
)
```

这个接口适合：

- 模板很短
- 只渲染一次
- 还不需要 include、自定义 filter、autoescape

## 推荐使用路径

这一节是本文的重点。`mold` 虽然对外 API 不多，但最好先建立一个整体框架：

- `render(...)` 解决快速渲染
- `Template` 解决模板复用
- `Engine` 解决扩展与组合

### 1. 小模板：`@mold.render(...)`

适合一次性渲染：

```moonbit
let output = @mold.render(
  "{{ greeting }}, {{ name }}!",
  @mold.object({
    "greeting": @mold.string("Hello"),
    "name": @mold.string("Alice"),
  }),
)
```

### 2. 重复渲染：`Template::parse(...).render(...)`

同一模板会被反复渲染时，建议先 parse 再 render：

```moonbit
let tpl = @mold.Template::parse("Hello, {{ name }}!")

let first = tpl.render(@mold.object({ "name": @mold.string("Alice") }))
let second = tpl.render(@mold.object({ "name": @mold.string("Bob") }))
```

这样可以避免每次渲染都重新解析模板。

### 3. 进阶场景：`Engine`

需要下面任意一种能力时，建议使用 `Engine`：

- `{% include "name" %}`
- `with_autoescape(true)`
- `register_filter(...)`

示例：

```moonbit
let engine = @mold.Engine::new().with_loader(fn(name) {
  match name {
    "header" => Some("Header: {{ title }}")
    _ => None
  }
})

let output = engine.render(
  "{% include \"header\" %}",
  @mold.object({ "title": @mold.string("My Report") }),
)
```

## 如何运行示例

仓库内的 examples 都是可运行的 main package。

```text
moon run src/examples/hello
moon run src/examples/report
moon run src/examples/email
moon run src/examples/include_loader
moon run src/examples/html_safe
moon run src/examples/custom_filter
moon run src/examples/from_json
moon run src/examples/site
```

各示例用途：

- `hello`: 最小插值与 filter
- `report`: 循环、条件、嵌套对象
- `email`: 更接近真实业务的文本模板
- `include_loader`: 多模板组合
- `html_safe`: HTML 输出与 `safe`
- `custom_filter`: 自定义 filter 注册
- `from_json`: JSON 到模板上下文的转换
- `site`: 静态网站批量渲染

## 上下文值模型

`mold` 不依赖反射，而是使用统一的 `Value` 模型：

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

常用构造器：

- `@mold.null()`
- `@mold.bool(...)`
- `@mold.int(...)`
- `@mold.float(...)`
- `@mold.string(...)`
- `@mold.array(...)`
- `@mold.object(...)`

如果你的数据已经是 `Json` 或 `Map[String, Value]`，也可以直接使用：

- `@mold.from_json(...)`
- `@mold.from_map(...)`

## 下一步

- 继续看 [`template-syntax.md`](template-syntax.md)
- 需要 `Engine` 时看 [`engine-guide.md`](engine-guide.md)
- 需要 HTML 输出时看 [`html-safety.md`](html-safety.md)
- 需要排查渲染失败时看 [`errors.md`](errors.md)
- 回到 [`README.md`](../README.md) 查看 API 摘要与示例入口
