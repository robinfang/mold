# Recipe：静态网站生成

这篇 recipe 面向个人博客、项目文档站、作品展示页等静态网站场景，演示如何用 `mold` 的 `Engine + Loader + include` 批量生成页面。

## 场景特点

静态网站通常包含：

- 多篇文章，每篇结构相同
- 公共的导航、页头、页脚
- 文章列表页
- 部分文章可能是草稿，不应出现在列表中

## 推荐组织方式

模板拆成可复用的组件：

- `head`：HTML 头部
- `nav`：导航
- `footer`：页脚
- `post`：单篇文章页
- `archive`：文章列表页

示例目录：

- [`src/examples/site/`](../../src/examples/site/)

运行：

```text
moon run src/examples/site
```

## 模板拆分

### head

```text
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>{{ title }} - {{ site_name }}</title>
</head>
<body>
  <header>
    <h1>{{ site_name }}</h1>
    {% include "nav" %}
  </header>
  <main>
```

### nav

```text
<nav><a href="/">Home</a> | <a href="/archive">Archive</a></nav>
```

### footer

```text
  </main>
  <footer><hr><p>© 2026 {{ site_name }}</p></footer>
</body></html>
```

### post

```text
{% include "head" %}
<article>
  <h2>{{ title }}</h2>
  <time>{{ date }}</time>
  {% if draft %}<p><em>draft</em></p>{% endif %}
  <div>{{ body | safe }}</div>
</article>
{% include "footer" %}
```

### archive

```text
{% include "head" %}
<h2>Posts</h2>
{% for post in posts %}
{% if not post.draft %}
  <article>
    <h3>{{ post.title }}</h3>
    <time>{{ post.date }}</time>
    <p>{{ post.summary }}</p>
  </article>
{% endif %}
{% endfor %}
{% include "footer" %}
```

## 批量渲染

核心流程：

1. 创建 `Engine`，设置 `with_autoescape(true)` 和 `with_loader(...)`
2. 用 `engine.parse(...)` 编译文章页和列表页模板
3. 准备文章数据
4. 对每篇文章调用 `tpl.render(...)` 生成最终 HTML

## 关键要点

### 使用 autoescape

输出 HTML 时务必开启 `with_autoescape(true)`，模板里普通插值会自动转义。如果文章正文本身就是 HTML，可以配合 `| safe` 输出：

```text
<div>{{ body | safe }}</div>
```

### 文章内容可以是 Markdown

`mold` 本身不处理 Markdown，但可以在程序里先把 Markdown 转成 HTML，再通过 `| safe` 传给模板：

```moonbit
let html_content = markdown_to_html(raw_markdown)
let ctx = @mold.object({
  "body": @mold.string(html_content),
  ...
})
```

### 草稿过滤

在列表页模板中用 `{% if not post.draft %}` 跳过草稿文章，这样文章数据可以统一管理，只在渲染阶段做过滤。

### 模板预编译

`engine.parse(...)` 会一次性编译主模板和所有 include 的子模板，后续重复渲染时不再调用 loader 或重新解析。这个特点在做批量生成时很有价值。

## 常见错误

- `MissingVariable`：模板里用了不在上下文里的字段名
- 草稿文章也出现在列表中：检查 `{% if not post.draft %}` 语法和变量名
- 输出空白过多：可以用 whitespace control

## 相关文档

- [`template-syntax.md`](../template-syntax.md)
- [`engine-guide.md`](../engine-guide.md)
- [`html-safety.md`](../html-safety.md)
- [`errors.md`](../errors.md)
