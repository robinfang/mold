# MoldLive

In-browser playground for [mold](https://github.com/robinfang/mold) — a template engine written in MoonBit, compiled to WASM.

This app now lives inside the main `mold` repository as `mold-live/`, so the demo and engine can be verified together.

**Live**: https://mold-live.run

![screenshot](docs/screenshot.png)

## Why

mold runs anywhere WASM runs. MoldLive proves it by rendering templates 100% in your browser, no server roundtrip.

## Stack

- TypeScript + Vite (no UI framework)
- CodeMirror 6
- Tailwind CSS
- mold compiled to WebAssembly (wasm-gc)

## Develop

```bash
cd ..
moon build --target wasm-gc
cp _build/wasm-gc/debug/build/wasm-export/wasm-export.wasm mold-live/public/mold.wasm
cd mold-live
pnpm install
pnpm dev
```

## Build

```bash
pnpm build
```

The deployed site uses `public/mold.wasm`. Rebuild and copy the WASM from the repository root whenever the MoonBit engine changes.

## Test

```bash
pnpm test
```

## TODO

- [ ] Add PWA manifest for full offline mode
- [ ] Persist last template in localStorage as fallback to URL state
