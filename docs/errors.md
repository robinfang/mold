# 错误排查

这篇文档汇总 `mold` 当前公开暴露的主要错误类型，帮助使用者快速判断错误属于语法问题、模板引用问题，还是上下文数据问题。

## 本文结构

1. 先看错误如何分类
2. 再看每类错误的典型触发方式
3. 最后给出排查顺序

## 1. 错误分类

`mold` 当前主要有这些错误：

- `LexerError((String, SourceSpan))`
- `ParserError((String, SourceSpan))`
- `UnknownFilter(String)`
- `DuplicateFilter(String)`
- `MissingVariable(String)`
- `MissingInclude(String)`
- `IncludeDepthExceeded`
- `TypeMismatch((String, String))`

可以粗分为四类：

1. 模板语法错误
2. filter 注册或调用错误
3. 上下文数据错误
4. include 解析与加载错误

## 2. 模板语法错误

### `LexerError`

这类错误一般发生在模板词法阶段，例如：

- 空的 `{{ }}`
- 空的 `{% if %}`
- 未闭合的块标签
- 非法 block tag

示例：

```text
{% if %}
```

可能得到：

```text
LexerError(("empty if condition", SourceSpan{...}))
```

排查方向：

- 先看模板标签是否闭合
- 再看 `if` / `for` / `include` 语法是否写完整
- 最后看 `SourceSpan` 给出的行列位置

### `ParserError`

这类错误一般表示 token 序列能被切出来，但结构关系不合法，例如：

- `else` 没有对应的 `if`
- `endif` / `endfor` 出现在错误位置
- 表达式里出现无法解析的 token 组合

示例：

```text
{% else %}
```

排查方向：

- 检查控制块是否成对出现
- 检查嵌套层次是否写错
- 检查比较、布尔表达式是否缺少一侧操作数

## 3. filter 相关错误

### `UnknownFilter`

当模板里调用了不存在的 filter 时，会报这个错误：

```text
{{ name | missing }}
```

排查方向：

- 检查 filter 名字拼写
- 如果是自定义 filter，确认 `Engine::register_filter(...)` 已经执行
- 确认调用时使用的是注册过 filter 的那个 `Engine`

### `DuplicateFilter`

当你：

- 试图覆盖内置 filter
- 或重复注册同名自定义 filter

会得到这个错误。

排查方向：

- 更换自定义 filter 名称
- 避免多次注册同名 filter

## 4. 上下文数据错误

### `MissingVariable`

当模板访问了上下文里不存在的路径时，会报这个错误：

```text
{{ user.name }}
```

如果 `user` 或 `user.name` 不存在，就会触发。

排查方向：

- 检查上下文对象是否真的包含对应字段
- 检查点路径拼写是否一致
- 检查循环体内变量名是否和 `for item in items` 里的 `item` 一致

### `TypeMismatch`

这类错误通常表示模板语义需要某种类型，但实际值不是那个类型。

常见情况：

- 对非数组值做 `for`
- 对不适合的值使用某些 filter

示例：

```text
{% for item in items %}...{% endfor %}
```

如果 `items` 实际是字符串而不是数组，就会报错。

排查方向：

- 检查 `Value` 的实际结构
- 检查 `from_json(...)` 转出来的字段类型
- 检查 filter 参数和输入值是否匹配

## 5. include 相关错误

### `MissingInclude`

这类错误说明模板写了 `{% include "name" %}`，但运行时没有找到对应模板。

常见原因：

- 根本没有配置 `Loader`
- `Loader` 返回了 `None`
- 模板名拼错了

排查方向：

- 先确认是否使用了 `Engine::with_loader(...)`
- 再确认模板名与 `Loader` 的分支匹配

注意：如果你使用 `Engine::parse(...)`，`MissingInclude` 和 include 内部的词法/语法错误可能在 parse 阶段就会提前抛出，而不是等到 `render(...)` 时才出现。这对于“parse once, render many”的使用方式来说，意味着错误会更早被定位。

### `IncludeDepthExceeded`

这类错误说明 include 链过深，通常是递归包含导致的。

例如：

- `a` include `b`
- `b` include `a`

或模板自己 include 自己。

排查方向：

- 检查 include 图是否有循环
- 检查是否存在意外的自包含模板

## 6. 推荐排查顺序

遇到渲染失败时，建议按下面顺序看：

1. 先判断是语法错误还是数据错误
2. 如果是 `LexerError` / `ParserError`，先看模板本身和 `SourceSpan`
3. 如果是 `MissingVariable` / `TypeMismatch`，先看传入的上下文值
4. 如果是 `MissingInclude` / `IncludeDepthExceeded`，先看 `Loader` 和 include 关系
5. 如果是 `UnknownFilter` / `DuplicateFilter`，先看 `Engine` 配置

## 7. 相关文档

- 模板语法：[`template-syntax.md`](template-syntax.md)
- `Engine` 用法：[`engine-guide.md`](engine-guide.md)
- HTML 输出：[`html-safety.md`](html-safety.md)
