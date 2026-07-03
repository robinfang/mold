# mold 文档

这组文档面向 `mold` 的使用者，目标是把“怎么开始、语法怎么写、什么时候该用哪层 API”讲清楚。

## 先看这一页能得到什么

这页不是语法手册，而是整个文档体系的总览。你可以在这里快速知道：

- `mold` 的用户文档分成哪几块
- 第一次接触时应该先看什么
- 不同问题分别去哪一篇文档找答案

## 文档总体框架

当前用户文档按“总分结构”组织：

1. `README.md` 负责项目入口、安装、能力摘要和全局导航。
2. `getting-started.md` 负责第一次上手和推荐使用路径。
3. `template-syntax.md` 负责模板语法本身。
4. 进阶文档负责 `Engine`、HTML 安全和错误排查。
5. examples 负责把常见使用姿势跑成可执行样例。

这样组织的目标是：先让用户建立整体认知，再进入具体主题，而不是在零碎说明之间来回跳转。

## 阅读顺序

1. [`getting-started.md`](getting-started.md)
2. [`template-syntax.md`](template-syntax.md)
3. 按需继续看 [`engine-guide.md`](engine-guide.md)、[`html-safety.md`](html-safety.md)、[`errors.md`](errors.md)
4. 回到 [`README.md`](../README.md) 查看 API 摘要与示例入口

## 文档入口

- [快速开始](getting-started.md)
  - 安装、最小示例、推荐使用路径、如何运行 examples
- [模板语法](template-syntax.md)
  - 插值、条件、循环、filter、include、空白控制、注释
- [Engine 使用指南](engine-guide.md)
  - `with_loader`、`with_autoescape`、`register_filter`、`Engine::parse(...)`
- [模板诊断 / Inspection](inspection.md)
  - 不渲染模板，收集变量路径、filter 名和 include 名
- [HTML 安全](html-safety.md)
  - 默认行为、autoescape、`| safe`、推荐实践
- [错误排查](errors.md)
  - 错误分类、常见触发方式、排查顺序
- [WASM 导出](wasm-export.md)
  - 构建、配置、JS 集成、返回格式
- [形式化验证 / Proof sandbox](scope-proof.md)
  - 实验性模型验证、WSL/Why3/Z3 运行方式
- Recipes
  - [报告生成](recipes/report-generation.md)
  - [邮件模板](recipes/email-template.md)
  - [include 与 Loader](recipes/include-loader.md)
  - [JSON 输入](recipes/json-input.md)
  - [静态网站](recipes/site-generation.md)

如果只想快速判断 `mold` 是否适合你的场景，先看 `README.md` 和 `getting-started.md` 即可。

## 示例入口

- [`src/examples/hello/`](../src/examples/hello/)
  - 最小变量插值与 filter
- [`src/examples/report/`](../src/examples/report/)
  - 循环、条件分支与嵌套对象
- [`src/examples/email/`](../src/examples/email/)
  - 更接近真实业务的文本模板
- [`src/examples/include_loader/`](../src/examples/include_loader/)
  - `Engine + Loader + include`
- [`src/examples/html_safe/`](../src/examples/html_safe/)
  - `with_autoescape(true)` 与 `| safe`
- [`src/examples/custom_filter/`](../src/examples/custom_filter/)
  - `Engine::register_filter(...)`
- [`src/examples/from_json/`](../src/examples/from_json/)
  - `from_json(...)`
- [`src/examples/site/`](../src/examples/site/)
  - 静态网站批量渲染

## 当前范围

`mold` 当前优先解决的是稳定的文本模板渲染：

- 模板解析到 AST
- 统一的上下文值模型
- 条件、循环、include、filter
- 结构化错误与源码位置

当前不覆盖：

- 模板继承
- 宏系统
- 异步模板
- 自动模板目录扫描

## 归档材料

早期规划、API 草案和历史兼容记录保存在 [`archive/`](archive/) 下。它们用于追溯设计过程，不作为当前用户文档入口。
