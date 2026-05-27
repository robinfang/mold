# MoonBit 模板引擎项目方案

> 适用场景：2026 MoonBit 开源生态项目贡献赛
> 当前定位：主赛题 / 主仓库方向

## 一、先给结论

这个项目的最佳策略不是做“又一个 Jinja2”，而是做一个：

- **边界清晰**
- **接口干净**
- **足够像正式开源包**
- **可验证、可 benchmark、可演示**

的一版 MoonBit 模板引擎。

一句话定义：

> 一个面向 MoonBit 生态的、可编译模板到 AST 并稳定渲染的轻量模板引擎。

不追求首版功能最全，追求：

- 语法完整到“能做真实模板”
- API 足够漂亮
- 测试和文档足够扎实
- 发布到 `mooncakes.io` 后别人真能 `moon add` 直接用

## 二、项目目标

首版目标只做三件事：

1. **把模板解析成 AST**
2. **把上下文数据稳定渲染成字符串**
3. **提供一套对 MoonBit 开发者友好的 API**

不把目标扩展到：

- SSR 全家桶
- 浏览器 runtime
- layout inheritance
- sandbox
- i18n
- 异步模板

这些都属于后续增强，不是比赛首版该背的负担。

## 三、建议项目名

优先考虑短、干净、像正式包名的名字：

1. `mold`
2. `glint`
3. `must.mbt`
4. `moonplate`
5. `moontmpl`

其中我最推荐：

- `mold`

原因：

- 短
- 好记
- 和“模板 / 成型”语义贴近
- 没有明显的技术债意味

## 四、建议功能边界

## 1. 首版必须支持

- 文本节点
- 变量插值：`{{ name }}`
- 点路径访问：`{{ user.name }}`
- 条件分支：`{% if cond %}...{% else %}...{% endif %}`
- 循环：`{% for item in items %}...{% endfor %}`
- 过滤器：`{{ name | upper }}`
- 基本空白控制：插值与块标签周边不产生奇怪换行
- 错误定位：至少给出行号 / 列号 / token 附近信息

## 2. 首版可选支持

- 布尔表达式：`and` / `or` / `not`
- 比较表达式：`== != > >= < <=`
- 默认值过滤器：`default`
- `join` / `trim` / `lower` / `escape`
- include（如果实现成本低）

## 3. 首版明确不做

- 模板继承
- 宏系统
- 自定义标签 DSL
- 异步加载
- 自动文件系统模板发现
- 完整 HTML auto-escape 策略矩阵

首版的原则是：

- **语法少一点，但每个语法都稳定**

## 4. 当前实现状态（截至 2026-05-27）

### 已完成

- 变量插值 `{{ expr }}`，支持点路径访问
- 条件分支 `{% if expr %}...{% else %}...{% endif %}`
- 循环 `{% for item in items %}...{% endfor %}`
- filter 链与 filter 参数（字符串、整数、路径变量）
- 自定义 filter 注册（`Engine::register_filter`），不可覆盖内置 filter
- 内置 filter：`upper`、`lower`、`trim`、`default`、`join`、`escape`
- 比较表达式：`== != < <= > >=`
- 布尔表达式：`and or not`，支持括号分组
- 模板包含：`{% include "name" %}` + `Loader` 机制
- 结构化错误定位（`SourceSpan`：start/end/line/column）
- 错误类型：`LexerError`、`ParserError`、`MissingVariable`、`UnknownFilter`、`DuplicateFilter`、`MissingInclude`、`IncludeDepthExceeded`、`TypeMismatch`
- `Template::parse` / `Template::render` 分层（parse once, render many）
- `Engine` 层扩展点
- 42 个测试 + benchmark
- 3 个示例程序（hello / report / email）

### 待实现

- 空白控制（whitespace control）
- Engine 级 autoescape 策略
- `from_json` / `from_map` 上下文转换辅助
- `Template::ast()` 调试接口

### 刻意保留不做

- 模板继承、宏系统、自定义标签 DSL
- 异步模板、自动模板发现
- 完整 HTML auto-escape 策略矩阵

## 五、上下文数据模型怎么设计

这是项目的核心设计点之一。

我不建议首版上来做“任意 MoonBit struct 自动反射”。

MoonBit 当前阶段，更稳的做法是定义一个模板值类型：

```text
Value =
  Null
  Bool
  Int
  Float
  String
  Array[Value]
  Object[Map[String, Value]]
```

然后提供：

- `from_json`
- `from_map`
- 若干便捷构造器

这样有三个好处：

1. 模板执行层最稳定
2. API 最容易讲清楚
3. 后续可以自然接 MoonBit 的 `ToJson` / `FromJson`

也就是说，模板引擎的核心不依赖“反射能力”，而依赖一个清晰的运行时值模型。

## 六、建议 API 设计

## 1. 面向用户的 API 要尽量简单

我建议首版外部 API 长这样：

```moonbit
let tpl = @mold.Template::parse("Hello, {{ user.name }}!")

let ctx = @mold.object({
  "user": @mold.object({
    "name": @mold.string("Alice"),
  }),
})

let out = tpl.render(ctx)
```

## 2. 再补一个一步式 API

```moonbit
let out = @mold.render(
  "{% for item in items %}- {{ item }}\n{% endfor %}",
  ctx,
)
```

## 3. 过滤器注册 API

```moonbit
let engine = @mold.Engine::new()
engine.register_filter("slug", slug_filter)
```

## 4. 模板包含 API

```moonbit
pub type Loader = (String) -> String?

pub fn Engine::new() -> Engine
pub fn Engine::with_loader(self : Engine, loader : Loader) -> Engine
```

模板中使用 `{% include "template_name" %}`，引擎通过 `Loader` 将模板名映射为源码字符串。被包含模板共享父模板上下文和作用域。

这样你就有四层：

- 快速函数式 API
- 可复用的 `Template`
- 可扩展的 `Engine`
- 可组合的模板包含体系

这个分层既专业，也不会太重。

## 七、内部结构建议

建议仓库内部按下面拆：

```text
src/
  token.mbt         // 词法 token
  lexer.mbt         // 词法分析
  ast.mbt           // 模板 AST
  parser.mbt        // 语法分析
  value.mbt         // 模板运行时值模型
  context.mbt       // 路径查找 / 作用域
  filter.mbt        // 内置过滤器与扩展点
  render.mbt        // 渲染器
  error.mbt         // 错误类型与位置信息
  top.mbt           // 对外 API

examples/
  hello/
  loops/
  email/

tests/
  lexer_test.mbt
  parser_test.mbt
  render_test.mbt
  error_test.mbt
```

这个结构的优点是：

- 模块职责非常清楚
- AI 辅助开发时不容易串文件
- 后续加 include / compile cache / extra filter 也好扩展

## 八、评委最看重的交付物

这个项目真正拿分不只靠代码，还靠下面四个东西：

## 1. README

README 至少要有：

- 这是什么
- 什么时候该用它
- 安装方法
- 30 秒示例
- 支持语法清单
- 已知限制

## 2. examples

建议至少给 3 个：

- `hello`：变量插值
- `report`：循环 + 条件
- `email`：更真实的模板

## 3. benchmark

建议加一个简单 benchmark：

- 渲染 1000 次小模板
- 渲染 100 次中模板
- 对比“每次 parse+render”与“预编译 Template 后 render”

这能非常直观证明你的工程思路是对的。

## 4. 错误信息演示

模板引擎最容易被低估的点就是：

- 错误信息是否可读

如果你能在 README 里展示：

- 语法错误时的定位
- 未知变量时的报错
- 过滤器不存在时的报错

评委会明显感受到“这是个正经工具”。

## 九、能不能用 moon prove

可以，但要选小点打。

不建议去证明整个 parser 正确。

建议证明：

- 路径解析逻辑的某个关键性质
- token 流消费的边界安全性
- 某个小型表达式求值器的恒等性质

你只需要做到：

- README 里能写一句“核心子模块使用 MoonBit 0.9 formal verification 验证了关键不变量”

这个比赛效果就已经很强了。

## 十、四周推进建议

## 第 1 周：最小系统跑通

- 确定语法子集
- 写 `Value` 模型
- 完成 lexer
- 完成最小 parser（文本 + 插值）
- 跑通 `parse -> render`

交付：

- Hello World 可运行
- 仓库骨架建立

## 第 2 周：控制流与错误处理

- 支持 `if/else`
- 支持 `for`
- 支持路径访问
- 补错误类型与定位
- 补 parser / render 测试

交付：

- 语法核心闭环完成

## 第 3 周：过滤器、文档、benchmark

- 做 4~6 个内置过滤器
- 做 `Template` / `Engine` API
- 写 examples
- 写 benchmark
- 整理 README

交付：

- 项目达到可演示状态

## 第 4 周：收尾与增强

- 视情况做 include 或一个小 prove
- 清理 API 命名
- 补 CI
- 发布 `mooncakes.io`
- 准备一页 PDF 申报材料

交付：

- 比赛提交版

## 十一、建议的成品叙事

你最终对外讲这个项目时，不要说：

- “我做了个模板引擎”

而要说：

> 我为 MoonBit 全栈与工具链生态补上了一个长期缺失的基础组件：一个支持预编译、过滤器扩展、错误定位和稳定测试的模板引擎，使 MoonBit 在服务端渲染、代码生成、邮件模板和文档渲染等场景具备更完整的工程能力。

这句话更像“生态贡献”，也更像评委愿意给分的叙述。

## 十二、下一步最值得做的事

从现在开始，最值得直接补的不是再分析，而是：

1. 定项目名
2. 定语法子集
3. 定对外 API

如果你愿意，我下一步可以直接继续写：

- `MoonBit模板引擎_API草案.md`
- 或 `MoonBit模板引擎_仓库初始化清单.md`

这两份会更接近真正开工。

## 十三、开源协议建议

我的首选建议是：

- **Apache-2.0**

原因：

1. 和 `moonbit-community` 里大量核心仓库风格一致
2. 对社区和商业使用都友好
3. 带专利授权条款，比 MIT 稍稳
4. 如果未来想进入 `moonbit-community`，迁移阻力更小

如果你特别偏好最简短协议，也可以退一步选 MIT。

不建议：

- GPL / AGPL

因为这会在 MoonBit 早期生态里明显抬高采用门槛。
