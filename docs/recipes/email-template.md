# Recipe：邮件模板

这篇 recipe 面向通知邮件、欢迎邮件、提醒邮件、运营触达等文本模板场景。

## 场景特点

邮件模板通常会包含：

- 用户称呼
- 条件段落
- 一组推荐动作或提醒项
- 联系方式或页脚信息

## 推荐使用方式

邮件模板通常可以先从文本模板开始：

- 如果是纯文本邮件：默认 `@mold.render(...)` 或 `Template`
- 如果是 HTML 邮件：建议切到 `Engine::with_autoescape(true)`

## 纯文本邮件示例

```moonbit
let template_source =
  #|Subject: Welcome, {{ user.name }}
  #|
  #|Hello {{ user.name }},
  #|{% if trial_active %}Your trial is active.{% else %}Your subscription is inactive.{% endif %}
```

这类模板适合用：

- 插值输出用户字段
- `if` 输出不同状态文案
- `for` 输出下一步行动项

## HTML 邮件建议

如果要输出 HTML 邮件，建议：

1. 使用 `Engine::with_autoescape(true)`
2. 默认让普通插值自动转义
3. 只有极少数可信 HTML 片段才用 `| safe`

相关说明：

- [`html-safety.md`](../html-safety.md)

## 推荐组织方式

邮件模板通常可以拆成：

- 标题与问候
- 状态段落
- 行动建议列表
- 页脚与支持信息

如果后面需要复用页头页脚，可以进一步升级到 `Engine + Loader + include`。

## 常见错误

- `MissingVariable`
  - 用户字段或支持邮箱字段缺失
- `UnknownFilter`
  - 模板里用了尚未注册的自定义 filter

## 对应示例

- [`src/examples/email/`](../../src/examples/email/)
- [`src/examples/html_safe/`](../../src/examples/html_safe/)
