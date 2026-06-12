# 模板诊断 / Inspection

`mold` 提供 inspection API，用来在不渲染模板的情况下分析模板依赖。

适用场景：

- 渲染前检查模板需要哪些上下文字段
- 统计模板使用了哪些 filters
- 收集模板 include 了哪些子模板
- 为编辑器提示、构建检查或调试工具提供基础数据

## 入口

`mold` 提供三层入口：

```moonbit
let info = @mold.inspect("Hello, {{ user.name }}!")

let template = @mold.Template::parse("Hello, {{ user.name }}!")
let info2 = template.inspect()

let engine = @mold.Engine::new()
let info3 = engine.inspect("Hello, {{ user.name }}!")
```

返回类型：

```moonbit
pub struct TemplateInspection {
  variables : Array[String]
  filters : Array[String]
  includes : Array[String]
}
```

## 变量收集

普通路径会被收集为完整路径：

```moonbit
let info = @mold.inspect("{{ user.name }} {{ org }}")
```

结果：

```text
variables = ["user.name", "org"]
```

## 循环作用域

循环局部变量不会被当作外部上下文依赖：

```moonbit
let info = @mold.inspect(
  "{% for item in items %}{{ item.name }} {{ loop.index }}{% endfor %}",
)
```

结果只包含外部输入：

```text
variables = ["items"]
```

`loop.*` 也不会被记录为外部变量。

## filters 与 includes

filter 链和 include 名会被分别收集：

```moonbit
let info = @mold.inspect(
  "{% include \"header\" %}{{ name | default(fallback) | upper }}",
)
```

结果：

```text
variables = ["name", "fallback"]
filters = ["default", "upper"]
includes = ["header"]
```

三个数组都会去重，并保持首次出现顺序。

## 边界

Inspection 只做静态依赖收集：

- 不检查传入的 `Value` 是否真的包含这些字段
- 不做类型推断
- 不改变 `render(...)` 的错误行为
- `Engine::inspect(...)` 会复用当前 `Engine` 的解析行为，因此 include 缺失或语法错误仍会抛出 `MoldError`

## 相关文档

- [`engine-guide.md`](engine-guide.md)
- [`template-syntax.md`](template-syntax.md)
- [`errors.md`](errors.md)
