# HTML 安全

这篇文档专门说明 `mold` 在 HTML 输出场景下的行为、边界和推荐用法。

最重要的一点先说清楚：`mold` 默认不自动转义 HTML。这样做是为了让它保持对通用文本场景的轻量和可控；一旦进入 HTML 输出场景，就应由调用方显式开启 autoescape。

## 本文结构

1. 先说明默认行为
2. 再说明 `with_autoescape(true)`
3. 再说明 `| safe` 的含义和风险
4. 最后给出推荐实践

## 1. 默认行为

默认情况下：

- `{{ text }}` 直接输出字符串内容
- 不自动做 HTML 转义

例如：

```moonbit
let output = @mold.render(
  "{{ html }}",
  @mold.object({ "html": @mold.string("<strong>raw</strong>") }),
)
```

输出会保留原始标签。

这对下面这些文本生成场景是合适的：

- 报告
- 邮件正文中的纯文本部分
- 配置文件
- 代码生成
- 文档片段

## 2. 显式开启 autoescape

如果你的目标输出是 HTML，建议显式使用：

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)
```

此时普通插值会自动做 HTML 转义：

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)

let output = engine.render(
  "<div>{{ body }}</div>",
  @mold.object({ "body": @mold.string("<strong>escaped</strong>") }),
)
```

输出会是：

```text
<div>&lt;strong&gt;escaped&lt;/strong&gt;</div>
```

## 3. `| safe` 的作用

如果某个值本身就是可信 HTML，可以用 `| safe` 阻止 autoescape：

```text
{{ trusted_html | safe }}
```

这表示：

- 当前值按原始 HTML 输出
- 其余普通插值仍遵循 autoescape 行为

示例：

```moonbit
let engine = @mold.Engine::new().with_autoescape(true)

let output = engine.render(
  "{{ body }} | {{ trusted_html | safe }}",
  @mold.object({
    "body": @mold.string("<strong>escaped</strong>"),
    "trusted_html": @mold.string("<em>kept</em>"),
  }),
)
```

## 4. 什么时候不要用 `safe`

不要把 `safe` 理解成“我想看到原样 HTML 时就随手加一下”。

只有在下面这种情况下才建议使用：

- 该值来自你自己完全可控的模板片段
- 或来自你已经做过独立安全审查的可信 HTML 源

不建议把来自用户输入、外部表单、第三方接口的原始 HTML 直接标成 `safe`。

## 5. 推荐实践

### 场景一：纯文本优先

如果你的输出主要是：

- 报告
- 邮件文本
- 配置文件

那就保持默认行为，不需要强行开启 autoescape。

### 场景二：HTML 页面或 HTML 邮件

如果输出会被浏览器或 HTML 渲染器直接消费：

1. 先开启 `with_autoescape(true)`
2. 默认让所有普通插值自动转义
3. 只有极少数可信 HTML 片段才用 `| safe`

## 6. 示例

对应示例：

- [`src/examples/html_safe/`](../src/examples/html_safe/)

运行：

```text
moon run src/examples/html_safe
```

## 7. 和其他文档的关系

- API 与 Engine 组合方式：看 [`engine-guide.md`](engine-guide.md)
- 基础模板语法：看 [`template-syntax.md`](template-syntax.md)
- 错误类型与排查：看 [`errors.md`](errors.md)
