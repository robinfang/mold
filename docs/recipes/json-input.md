# Recipe：JSON 数据输入

这篇 recipe 面向“上游数据已经是 JSON”的场景，例如接口返回、配置文件、静态数据文件、脚本生成结果等。

## 核心做法

`mold` 提供了：

- `@mold.from_json(json)`
- `@mold.from_map(map)`

这意味着你可以先把原始数据转成统一的 `Value`，再交给模板渲染，而不需要在模板层关心 JSON 解析细节。

## 最小示例

```moonbit
let json = @json.parse(
  "{\"project\": \"mold\", \"active\": true, \"tags\": [\"moonbit\", \"template\"]}",
)
let ctx = @mold.from_json(json)

let output = @mold.render(
  "{{ project }} (active={{ active }}) -> {{ tags | join(\", \") }}",
  ctx,
)
```

## 什么时候适合 `from_json(...)`

- 上游已经给了标准 JSON
- 你不想手写一层 `@mold.object(...)`
- 你希望模板上下文结构和原始数据结构尽量一致

## 什么时候适合 `from_map(...)`

- 你的数据已经在程序里被整理成 `Map[String, Value]`
- 你希望在进入模板前先做一层显式转换或清洗

## 推荐实践

1. JSON 解析和模板渲染分成两步
2. 先检查关键字段是否存在
3. 对数组字段配合 `for`
4. 对可选字段配合 `default(...)` 或 `if`

## 常见错误

- `MissingVariable`
  - JSON 里字段名与模板路径不一致
- `TypeMismatch`
  - 预期数组，实际字段是字符串或对象

## 对应示例

- [`src/examples/from_json/`](../../src/examples/from_json/)
- [`getting-started.md`](../getting-started.md)
