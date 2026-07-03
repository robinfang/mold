# mold 参赛说明

`mold` 是一个面向 MoonBit 生态的轻量模板引擎，覆盖模板解析、AST、统一 `Value` 模型、渲染、错误定位、WASM 导出和浏览器 Demo。

## 项目亮点

- MoonBit 原生实现，公开 API 通过 `src/top.mbt` 收口。
- 语法覆盖真实文本模板需要的插值、条件、循环、filter、include、空白控制和注释。
- `Template::parse(...).render(...)` 支持 parse once, render many，并有 benchmark 验证。
- `Engine` 提供 loader、autoescape、自定义 filter 和 inspection 扩展点。
- MoldLive 位于 `mold-live/`，将 `mold` 编译为 WASM 后在浏览器内直接渲染，无后端。

## 5 分钟演示脚本

1. 打开 <https://mold-live.run>，展示三栏编辑器和默认 Hello 示例。
2. 切换 Email、SVG Card、Offline Report，说明同一引擎可生成文本、SVG 和报告。
3. 改动 JSON 数据，展示浏览器内实时渲染。
4. 输入一个模板错误，展示 WASM 返回的结构化错误。
5. 回到代码仓库，展示 `src/` 编译链路、测试数量和 WASM 导出。

## 可复现命令

```text
moon fmt
moon check
moon test
moon bench
moon build --target wasm-gc
node mold_live_smoke.mjs
cp _build/wasm-gc/debug/build/wasm-export/wasm-export.wasm mold-live/public/mold.wasm
cd mold-live
pnpm install --frozen-lockfile
pnpm test
pnpm build
```

## 当前边界

- 不支持模板继承。
- 不支持宏系统。
- 不支持异步模板。
- 不支持自动模板目录扫描。

这些边界是刻意保留的，目标是保持模板语言轻量、可验证、适合 MoonBit 生态首版交付。
