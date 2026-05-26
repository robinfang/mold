# AGENTS

## Scope

- Treat this repo's real MoonBit module as `src/` only. `moon.mod` sets `source: "src"`.
- `moonbit-docs-main/` is reference material, not part of `mold`'s implementation. Do not edit it for `mold` tasks unless the user explicitly asks.

## Module Layout

- Root package: `src/`
- Example main packages: `src/examples/hello/`, `src/examples/report/`, `src/examples/email/`
- Current public API is wired through `src/top.mbt`.
- Full compilation chain: `token` -> `lexer` -> `ast` -> `parser` -> `context` -> `render` -> `top`.
- Built-in filters live in `src/filter.mbt`.
- Error types live in `src/error.mbt`.
- Runtime value model lives in `src/value.mbt`.

## Commands

- Full verification order matches CI:
  - `moon fmt`
  - `moon check`
  - `moon test`
- Benchmarks:
  - `moon bench`
- Local cleanup before finishing a change:
  - `moon fmt`
  - `moon check`
  - `moon test`

## Repo-Specific Constraints

- Keep the worktree warning-free. Do not stop at "tests pass" if `moon check` still emits warnings.
- `fn main` cannot call error-raising functions directly. In example binaries, wrap render calls with `catch` or `try` inside `main`.
- Prefer the newer MoonBit APIs already used here:
  - use `moon.mod` / `moon.pkg`, not legacy `*.json` manifests
  - use `StringBuilder`, not `@buffer.write_string` paths that trigger deprecation warnings
- Benchmark closures passed to `b.bench(...)` must be non-raising. Catch or convert render/parse errors inside the closure.
- Blackbox test files (`*_test.mbt`) automatically import the current package. Use `@mold` to access public API.
- `Map::from_array([(k, v)])` creates maps with computed keys.
- MoonBit `for .. in` loop uses `for x in array {}` or `for x in 0..<n {}` range syntax, NOT C-style `for`.

## Editing Guidance

- Preserve the small-step architecture: compile chain is `token -> lexer -> parser -> render -> top`.
- If you change template syntax behavior, update or add tests in `src/mold_test.mbt` in the same change.
- AST nodes live in `src/ast.mbt` (`Node` / `Expr` enum). New syntax features start there.
- Token types are private in `src/token.mbt`. Lexer is in `src/lexer.mbt` with two-phase block/interpolation parsing.
- Filter implementations belong in `src/filter.mbt`. `apply_filter` dispatches by name.
- Context resolution (with scope support for `for` loops) lives in `src/context.mbt`.
