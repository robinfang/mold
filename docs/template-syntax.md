# 模板语法

这份文档只说明 `mold` 当前已经支持的模板语法，并给出最小可运行示例。

阅读方式建议是：先从插值、条件、循环这三个核心块看起，再看 filter、include、空白控制和注释这些增强能力。

## 本文结构

这份语法文档按“基础到增强”的顺序展开：

1. 基础输出：文本、插值、点路径
2. 控制结构：`if`、`for`、嵌套控制块
3. 表达式与 filters
4. 模板组合：include
5. 输出修饰：空白控制、注释、HTML 输出

## 1. 纯文本

模板里没有标签时，输出保持原样：

模板：

```text
hello, mold
```

输出：

```text
hello, mold
```

## 2. 插值 `{{ expr }}`

模板：

```text
Hello, {{ name }}!
```

上下文：

```moonbit
@mold.object({ "name": @mold.string("Alice") })
```

输出：

```text
Hello, Alice!
```

## 3. 点路径访问

模板：

```text
{{ user.name }}
```

上下文：

```moonbit
@mold.object({
  "user": @mold.object({ "name": @mold.string("Alice") }),
})
```

输出：

```text
Alice
```

## 4. 条件分支

模板：

```text
{% if active %}enabled{% else %}disabled{% endif %}
```

输出：

```text
enabled
```

`mold` 支持嵌套控制块，因此 `if` 里可以继续写 `if` 或 `for`。

表达式内也支持字面量：

- `true` / `false`
- `null`
- 整数和浮点数，例如 `42`、`3.14`、`-0.5`

示例：

```text
{% if active == true %}enabled{% endif %}
{{ price | default(0.0) }}
```

## 5. 循环

模板：

```text
{% for item in items %}- {{ item }}
{% endfor %}
```

上下文：

```moonbit
@mold.object({
  "items": @mold.array([
    @mold.string("apple"),
    @mold.string("banana"),
  ]),
})
```

输出：

```text
- apple
- banana
```

`for` 同样支持嵌套，也可以在循环体内继续写 `if`。

### 循环元变量 `loop`

在 `for` 循环体内，`mold` 自动注入一个 `loop` 对象，提供当前迭代的元信息：

| 属性 | 说明 | 示例值 |
|---|---|---|
| `loop.index` | 1-based 序号 | 1, 2, 3 |
| `loop.index0` | 0-based 序号 | 0, 1, 2 |
| `loop.first` | 是否为第一个元素 | true, false |
| `loop.last` | 是否为最后一个元素 | true, false |
| `loop.length` | 数组总长度 | 3 |

示例：

```text
{% for item in items %}
{{ loop.index }}. {{ item }}{% if not loop.last %}, {% endif %}
{% endfor %}
```

假设 `items` 是 `["a", "b"]`，输出：

```text
1. a, 2. b
```

嵌套 `for` 中，每个循环拥有独立的 `loop` 作用域，互不干扰。

## 6. filters

模板：

```text
{{ name | upper }}
{{ items | join(", ") }}
{{ title | default("Untitled") }}
```

当前内置 filters：

- `upper`
- `lower`
- `trim`
- `default(...)`
- `join(...)`
- `escape`
- `length`
- `safe`

## 7. 比较与布尔表达式

模板表达式支持：

- 比较：`== != < <= > >=`
- 布尔：`and or not`
- 括号分组：`(a or b) and c`

示例：

```text
{% if user.role == "admin" and active %}allowed{% endif %}
```

## 8. include

模板：

```text
{% include "header" %}
Body
```

`include` 需要 `Engine` 提供 `Loader`：

```moonbit
let engine = @mold.Engine::new().with_loader(fn(name) {
  match name {
    "header" => Some("Header: {{ title }}")
    _ => None
  }
})
```

被包含模板共享父模板的上下文和作用域。

## 9. whitespace control

支持：

- `{%-`
- `-%}`
- `{{-`
- `-}}`

示例：

```text
hello   {{- name -}}   world
```

输出：

```text
helloAliceworld
```

## 10. 注释

模板注释不会进入最终输出：

```text
hello{# this is a comment #}world
```

输出：

```text
helloworld
```

## 11. HTML 输出

`mold` 默认不自动转义 HTML。

如果你要渲染 HTML，建议显式启用：

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)
```

如果某个值本身就是可信 HTML，可以用：

```text
{{ trusted_html | safe }}
```

## 12. 典型组合方式

### 小模板

- `@mold.render(...)`

### 可复用模板

- `Template::parse(...).render(...)`

### 多模板组合

- `Engine::new().with_loader(...)`

## 13. 当前不支持的能力

- 模板继承
- 宏系统
- 异步模板
- 自动模板目录扫描

## 14. 对应示例

- [`src/examples/hello/`](../src/examples/hello/)
- [`src/examples/report/`](../src/examples/report/)
- [`src/examples/email/`](../src/examples/email/)
- [`src/examples/include_loader/`](../src/examples/include_loader/)
- [`src/examples/html_safe/`](../src/examples/html_safe/)
- [`src/examples/custom_filter/`](../src/examples/custom_filter/)
- [`src/examples/from_json/`](../src/examples/from_json/)
- [`src/examples/site/`](../src/examples/site/)

## 15. 继续阅读

- 模板组合与 `Engine`：[`engine-guide.md`](engine-guide.md)
- HTML 输出：[`html-safety.md`](html-safety.md)
- 错误排查：[`errors.md`](errors.md)
