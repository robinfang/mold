# Recipe：报告生成

这篇 recipe 面向“结构化文本输出”场景，例如周报、库存报告、汇总清单、导出摘要等。

## 适合什么情况

如果你的输出同时具备下面几类特点，`mold` 很适合：

- 固定的版式骨架
- 一组标量字段
- 一到多层列表数据
- 条件段落

典型例子：

- 周报
- 库存报告
- 订单摘要
- 导出说明

## 推荐使用方式

报告生成通常建议走这条路径：

1. 用 `Template::parse(...).render(...)` 或 `Engine::render(...)`
2. 把业务数据整理成 `Value`
3. 对列表部分用 `{% for %}`
4. 对可选段落用 `{% if %}`

## 最小示例

```moonbit
let template_source =
  #|Weekly Inventory Report
  #|Store: {{ store.name }}
  #|{% if active %}Status: Active{% else %}Status: Paused{% endif %}
  #|{% for item in items %}- {{ item.name }} x {{ item.count }}
  #|{% endfor %}

let output = @mold.render(
  template_source,
  @mold.object({
    "active": @mold.bool(true),
    "store": @mold.object({ "name": @mold.string("Moon Market") }),
    "items": @mold.array([
      @mold.object({
        "name": @mold.string("apple"),
        "count": @mold.int(12),
      }),
    ]),
  }),
)
```

## 推荐模板组织方式

如果报告结构开始变长，建议把公共头尾拆成 include：

- `header`
- `section`
- `footer`

对应做法见：

- [`src/examples/include_loader/`](../../src/examples/include_loader/)
- [`engine-guide.md`](../engine-guide.md)

## 推荐数据组织方式

报告类模板通常建议把上下文整理成：

- 一个顶层对象
- 对象里包含标量字段和数组字段
- 数组元素再用对象表示一行记录

这样模板会更稳定，也更容易维护路径，例如：

- `store.name`
- `item.count`

## 常见错误

- `MissingVariable`
  - 某个字段名和上下文字段不一致
- `TypeMismatch`
  - `for` 期望数组，但实际传入了字符串或对象

排查时可结合：[`errors.md`](../errors.md)

## 对应示例

- [`src/examples/report/`](../../src/examples/report/)
- [`src/examples/include_loader/`](../../src/examples/include_loader/)
