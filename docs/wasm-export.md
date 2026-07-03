# WASM 导出指南

这篇文档说明如何将 mold 编译为 WebAssembly 模块，在浏览器或 Node.js 中直接调用。

## 本文结构

1. 先看构建命令和配置
2. 再看导出接口和返回值格式
3. 最后看 JS 端集成示例

## 1. 构建

在 `src/wasm-export/` 目录下执行：

```text
moon build --target wasm-gc
```

产物路径：

```text
_build/wasm-gc/debug/build/wasm-export/wasm-export.wasm
```

同步到本仓库内置 Demo：

```text
cp _build/wasm-gc/debug/build/wasm-export/wasm-export.wasm mold-live/public/mold.wasm
```

## 2. moon.pkg 配置

`src/wasm-export/moon.pkg` 的关键配置项：

```moonbit
import {
  "robinfang/mold",
  "moonbitlang/core/json",
}

supported_targets = "wasm-gc"

options(
  "is-main": true,
  link: {
    "wasm-gc": {
      "use-js-builtin-string": true,
      "exports": ["mold_render"],
    },
  },
)
```

- `supported_targets = "wasm-gc"`：该包只面向 wasm-gc 编译目标
- `"use-js-builtin-string": true`：启用 MoonBit String ↔ JS string 通过 externref 零拷贝
- `"exports": ["mold_render"]`：导出 `mold_render` 函数

## 3. 导出接口

### 函数签名

```moonbit
pub fn mold_render(template : String, data_json : String) -> String
```

- `template`：mold 模板源码
- `data_json`：JSON 数据字符串
- 返回值：始终为 **JSON 信封字符串**

### 返回格式

**成功**：

```json
{"output":"Hello WASM!"}
```

**失败**：

```json
{"error":{"kind":"template","message":"unclosed interpolation tag","line":1,"column":3}}
{"error":{"kind":"json","message":"invalid JSON","line":0,"column":0}}
```

- `kind`：`"template"` 或 `"json"`
- `message`：具体错误信息
- `line` / `column`：错误位置（`LexerError` / `ParserError` 有精确值，其余为 0）

### 错误类型映射

`mold` 的 8 种 `MoldError` 逐一映射：

| 错误变体 | kind | line/column |
|---|---|---|
| `LexerError` | template | 精确位置 |
| `ParserError` | template | 精确位置 |
| `UnknownFilter` | template | 0/0 |
| `DuplicateFilter` | template | 0/0 |
| `MissingVariable` | template | 0/0 |
| `MissingInclude` | template | 0/0 |
| `IncludeDepthExceeded` | template | 0/0 |
| `TypeMismatch` | template | 0/0 |
| JSON 解析失败 | json | 0/0 |

成功与失败通过是否有 `error` 字段区分，无歧义。

## 4. JS 端集成

### 加载与调用

```js
const response = await fetch("/mold.wasm");
const buffer = await response.arrayBuffer();

const { instance } = await WebAssembly.instantiate(buffer, {}, {
  builtins: ["js-string"],
  importedStringConstants: "_",
});

instance.exports._start();

const raw = instance.exports.mold_render(
  "Hello {{ name }}!",
  `{"name":"WASM"}`
);

const result = JSON.parse(raw);
if (result.error) {
  console.error(result.error.message);
} else {
  console.log(result.output); // "Hello WASM!"
}
```

### 关键点

- 第三个参数 `{ builtins: ["js-string"], importedStringConstants: "_" }` 为必需，告诉运行时提供 JS 字符串内置函数和编译期字符串常量
- `_start()` 必须在首次调用 `mold_render` 前执行一次
- MoonBit `String` ↔ JS `string` 通过 `externref` 直接映射，无需手动内存管理
- 无 `alloc` / `dealloc` / `memory` — GC 自动托管

### 环境要求

- Chrome 128+
- Node.js 24.13.1+
- 其他支持 JS String Builtins 提案的 WASM 运行时

## 5. 最小可运行示例

完整的 Node.js 验证脚本：[`mold_live_smoke.mjs`](../mold_live_smoke.mjs)

```bash
moon build --target wasm-gc
node mold_live_smoke.mjs
```

如果要验证其他 WASM 文件，可以设置 `MOLD_WASM_PATH`：

```bash
MOLD_WASM_PATH=mold-live/public/mold.wasm node mold_live_smoke.mjs
```

预期输出：

```text
1. basic: OK: Hello MoonBit!
2. length: OK: 3
3. loop: OK: 1:a
2:b

5. syntax err: {"kind":"template","message":"unclosed interpolation tag","line":1,"column":1}
6. unknown filter: {"kind":"template","message":"unknown filter: bad","line":0,"column":0}
7. missing var: {"kind":"template","message":"missing variable: missing","line":0,"column":0}
8. invalid JSON: {"kind":"json","message":"invalid JSON","line":0,"column":0}
```

## 6. 相关文档

- [快速开始](getting-started.md)
- [模板语法](template-syntax.md)
- [Engine 使用指南](engine-guide.md)
- [MoldLive 在线游乐场](https://mold-live.run)
- [MoldLive 子应用](../mold-live/)
