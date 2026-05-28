# Engine 使用指南

这篇文档专门说明 `Engine` 这一层 API 的职责、适用场景和推荐使用方式。

如果你还在判断是否需要 `Engine`，可以先看 [`getting-started.md`](getting-started.md) 里的三种推荐使用路径；如果你已经确定需要 include、autoescape 或自定义 filter，就直接看这篇。

## 本文结构

1. 先说明什么时候该用 `Engine`
2. 再分别看 `with_loader`、`with_autoescape`、`register_filter`
3. 最后看 `Engine::parse(...)` 这条可复用路径

## 1. `Engine` 解决什么问题

`mold` 对外有三层主要使用方式：

- `@mold.render(...)`
- `Template::parse(...).render(...)`
- `Engine`

其中 `Engine` 负责扩展与组合。只要你需要下面任意一种能力，就应该考虑切到 `Engine`：

- `{% include "name" %}`
- HTML 输出下的 `with_autoescape(true)`
- `register_filter(...)` 注册自定义 filter
- 带引擎配置的 parse once, render many

## 2. `Engine::new()`

最基础的入口是：

```moonbit
let engine = @mold.Engine::new()
```

默认状态下：

- 没有 loader
- autoescape 关闭
- 已加载内置 filters

## 3. `with_loader(...)`

如果模板里要使用 `{% include "name" %}`，需要给 `Engine` 提供一个 `Loader`：

```moonbit
let engine = @mold.Engine::new().with_loader(fn(name) {
  match name {
    "header" => Some("Header: {{ title }}")
    _ => None
  }
})
```

`Loader` 的类型是：

```moonbit
pub type Loader = (String) -> String?
```

也就是说，`Loader` 接收模板名，返回模板源码或 `None`。

### 推荐理解方式

- 模板作者在模板里写模板名
- `Engine` 通过 `Loader` 决定这个名字映射到哪一段模板源码
- 被 include 的模板共享父模板的上下文和当前作用域

对应示例：

- [`src/examples/include_loader/`](../src/examples/include_loader/)

运行：

```text
moon run src/examples/include_loader
```

## 4. `with_autoescape(true)`

如果目标输出是 HTML，建议显式打开 autoescape：

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)
```

打开后，普通插值会自动做 HTML 转义；如果某个值本身就是可信 HTML，可以配合 `| safe` 使用。

对应示例：

- [`src/examples/html_safe/`](../src/examples/html_safe/)

运行：

```text
moon run src/examples/html_safe
```

更完整的说明见：[`html-safety.md`](html-safety.md)

## 5. `register_filter(...)`

`Engine` 支持注册自定义 filter：

```moonbit
pub fn Engine::register_filter(
  self : Engine,
  name : String,
  filter : Filter,
) -> Unit raise MoldError
```

`Filter` 的类型是：

```moonbit
pub type Filter = (Value, Array[Value]) -> Value
```

最常见的用法是把某段领域逻辑包成一个模板 filter，然后在模板里通过 `| name(...)` 使用。

示例：

```moonbit
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

let engine = @mold.Engine::new()
engine.register_filter("suffix", suffix_filter)
```

对应示例：

- [`src/examples/custom_filter/`](../src/examples/custom_filter/)

运行：

```text
moon run src/examples/custom_filter
```

### 约束

- 不能覆盖内置 filter
- 不能重复注册同名自定义 filter
- 这些情况会返回 `DuplicateFilter`

## 6. `Engine::parse(...)`

如果你既需要 `Engine` 提供的能力，又要重复渲染同一模板，建议用：

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)
let tpl = engine.parse("<h1>{{ title }}</h1>")

let first = tpl.render(@mold.object({ "title": @mold.string("A") }))
let second = tpl.render(@mold.object({ "title": @mold.string("B") }))
```

这样模板在 parse 阶段就会携带当前 `Engine` 的 filters、loader 和 autoescape 配置。

另外，`Engine::parse(...)` 在解析主模板的同时，也会提前编译所有 `{% include %}` 引用的子模板。后续 `render(...)` 时会直接复用已编译的 AST，不再重复调用 loader 或重新解析。这意味着：

- 同一个 `Template` 重复渲染时，loader 只会被调用一次
- include 不存在、include 递归过深等问题可能会在 parse 阶段提前暴露

## 7. 什么时候不要上来就用 `Engine`

如果你只是：

- 渲染一个短模板
- 没有 include
- 没有 HTML autoescape
- 不需要自定义 filter

那直接用 `@mold.render(...)` 或 `Template::parse(...).render(...)` 会更简单。

## 8. 对应文档与示例

- [`getting-started.md`](getting-started.md)
- [`html-safety.md`](html-safety.md)
- [`errors.md`](errors.md)
- [`src/examples/include_loader/`](../src/examples/include_loader/)
- [`src/examples/html_safe/`](../src/examples/html_safe/)
- [`src/examples/custom_filter/`](../src/examples/custom_filter/)
