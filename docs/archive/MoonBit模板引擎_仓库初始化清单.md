# MoonBit 模板引擎仓库初始化清单

> **状态：已归档（2026-05-27）**
> 本文档是项目启动前的初始化 checklist。当前仓库已远超此阶段，保留作为历史参考。
> 当前用户文档以 `README.md` 和 `docs/index.md` 为准。

> 目标：把比赛项目从“一个想法”变成“一个立刻能提交申报的仓库骨架”。

## 一、仓库名

优先建议：

- `mold`

备选：

- `moonplate`
- `moontmpl`

## 二、首日必须有的文件

```text
README.md
LICENSE
moon.mod.json
moon.pkg.json
.gitignore
.github/workflows/ci.yml
src/top.mbt
src/value.mbt
src/error.mbt
tests/smoke_test.mbt
examples/hello/main.mbt
```

## 三、README 第一版必须写什么

首版 README 不追求长，必须有：

1. 这是什么
2. 为什么 MoonBit 生态需要它
3. 一段 30 秒示例
4. 当前支持哪些语法
5. 当前不支持哪些语法
6. 如何运行测试
7. 计划发布到 `mooncakes.io`

## 四、Moon 配置建议

### `moon.mod.json`

建议：

- 明确模块名
- 明确版本号先用 `0.1.0`
- 如果首版只测本地运行，可以不锁 target
- 如果要强调全 target 兼容，后面再补 `supported_targets`

### `moon.pkg.json`

建议：

- 对外导出只有 `top.mbt`
- 内部模块都从 `top.mbt` re-export

这样对外 API 会比较干净。

## 五、CI 第一版建议

CI 只做最必要的三步：

1. `moon check`
2. `moon test`
3. `moon fmt --check`

不要一开始加太多矩阵和复杂动作。

## 六、首批测试清单

首批测试建议至少有：

### 词法测试

- 普通文本
- 插值标签
- 控制块标签
- 非法结束标签

### 语法测试

- 单个变量插值
- `if / else / endif`
- `for / endfor`
- 过滤器链

### 渲染测试

- 变量替换
- 嵌套对象访问
- 循环输出
- 条件渲染
- 缺失变量报错

### 错误测试

- 未闭合标签
- 未知过滤器
- 类型不匹配

## 七、申报前最重要的 commits 结构

章程要求 GitHub 仓库要有 **10~20 个有效 commits**。

建议按下面拆，避免看起来像硬凑：

1. init repo skeleton
2. add README first draft
3. add value model
4. add basic error model
5. add lexer tokens
6. add lexer implementation
7. add parser for interpolation
8. add basic render path
9. add smoke tests
10. add example hello template
11. improve error spans
12. add CI workflow

这样既满足章程，也看起来像真实开发过程。

## 八、开源协议建议

优先建议：

- **Apache-2.0**

原因：

1. `moonbit-community` 里大量核心仓库用的就是 Apache-2.0
2. 包含专利授权条款，比 MIT 更稳妥
3. 商业使用友好，社区接受度高
4. 如果后续想把项目并入 `moonbit-community`，风格更一致

### 什么时候选 MIT

如果你非常想要：

- 协议最短
- 最少文字负担
- 最宽松的复制氛围

那也可以选 MIT。

### 为什么不建议 GPL/AGPL

- MoonBit 生态还很早，强 copyleft 会直接降低采用率
- 比赛评委未必喜欢额外法律复杂性

### 一个重要提醒

如果你参考了别的模板引擎：

- 可以参考语法和设计
- 但不要直接复制其实现代码，除非许可证兼容且你明确标注

建议策略：

- 参考 `Mustache / Handlebars / Jinja2 / Go templates` 的语法思路
- **实现代码自己写**
- README 里注明“语法设计参考了哪些项目”

## 九、建议的仓库第一版目录

```text
src/
  top.mbt
  value.mbt
  error.mbt
  token.mbt
  lexer.mbt
  ast.mbt
  parser.mbt
  render.mbt
  filter.mbt

tests/
  smoke_test.mbt
  lexer_test.mbt
  parser_test.mbt
  render_test.mbt

examples/
  hello/
```

## 十、最小可申报状态

达到下面状态，就已经可以准备申报材料：

- README 初版完成
- 仓库公开
- 10~20 个有效 commits
- 能解析并渲染 `{{ name }}`
- 有一个 `if` 或 `for`
- 有基础测试
- CI 绿

也就是说：

- **不需要等全部做完再报名**

## 十一、下一步

从这里往下，最值得马上补的是：

1. 词法规则细化
2. 语法 AST 草图
3. README 第一版示例
