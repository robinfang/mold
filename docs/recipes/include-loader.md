# Recipe：include 与 Loader

这篇 recipe 面向模板需要拆分复用的场景，例如报告页头页脚、邮件签名、静态站导航、配置片段和脚手架模板片段。

## 核心做法

`mold` 不内置模板目录扫描。模板从哪里来由宿主程序决定，`mold` 只要求提供一个 `Loader`：

```moonbit
pub type Loader = (String) -> String?
```

也就是说，模板里写 `{% include "name" %}`，`Loader` 负责把 `"name"` 映射为模板源码。

## 最小示例

```moonbit
let engine = @mold.Engine::new().with_loader(fn(name) {
  match name {
    "header" => Some("Report: {{ title }}\n")
    "row" => Some("- {{ item.name }} x {{ item.count }}\n")
    "footer" => Some("Owner: {{ owner }}")
    _ => None
  }
})

let source =
  #|{% include "header" %}
  #|{% for item in items %}{% include "row" %}{% endfor %}
  #|{% include "footer" %}

let output = engine.render(source, ctx)
```

对应示例：

- [`src/examples/include_loader/`](../../src/examples/include_loader/)

运行：

```text
moon run src/examples/include_loader
```

## 接入文件或目录

如果模板来自文件系统，推荐把文件读取逻辑放在应用层，再适配成 `Loader`。这样 `mold` 保持跨 target 的小核心，文件 IO、打包、缓存和权限策略都由宿主程序控制。

常见组织方式：

```text
templates/
  layout
  nav
  footer
  pages/report
```

宿主程序可以在启动时把这些文件读入 `Map[String, String]`，再提供 loader：

```moonbit
fn make_loader(templates : Map[String, String]) -> @mold.Loader {
  fn(name) { templates.get(name) }
}
```

如果目标环境不适合直接文件 IO，例如浏览器 WASM，可以把模板作为构建产物、JSON、内嵌字符串或远端接口结果预加载成同样的映射表。

## 预编译行为

使用 `Engine::parse(...)` 时，主模板和所有 include 模板会在 parse 阶段一起编译：

```moonbit
let tpl = engine.parse("{% include \"layout\" %}")
let first = tpl.render(first_ctx)
let second = tpl.render(second_ctx)
```

这意味着：

- 同一个 `Template` 重复渲染时不会反复调用 loader
- 缺失 include 会更早暴露
- include 链过深会在 parse 阶段触发 `IncludeDepthExceeded`

## 命名建议

- 用稳定的逻辑名，例如 `layout`、`email/footer`、`pages/report`
- 不在模板里暴露本机绝对路径
- 由宿主程序决定逻辑名到文件路径、打包资源或远端资源的映射
- 对用户可编辑模板，建议限制可加载的名称集合

## 常见错误

- `MissingInclude`：模板名拼错，或 loader 返回了 `None`
- `IncludeDepthExceeded`：include 出现循环或链路过深
- `MissingVariable`：被 include 的模板访问了当前上下文里不存在的字段

## 相关文档

- [`engine-guide.md`](../engine-guide.md)
- [`template-syntax.md`](../template-syntax.md)
- [`errors.md`](../errors.md)
- [`site-generation.md`](site-generation.md)
