import { readFileSync } from "node:fs";

const bytes = readFileSync(
  "Z:/agentworkspace/mold/_build/wasm-gc/debug/build/wasm-export/wasm-export.wasm",
);

const { instance } = await WebAssembly.instantiate(bytes, {}, {
  builtins: ["js-string"],
  importedStringConstants: "_",
});

instance.exports._start();
const r = instance.exports.mold_render;

function test(label, template, data) {
  const raw = r(template, JSON.stringify(data));
  const parsed = JSON.parse(raw);
  console.log(
    `${label}:`,
    parsed.output
      ? `OK: ${parsed.output}`
      : `ERR: ${JSON.stringify(parsed.error)}`,
  );
}

// Success cases
test("1. basic", "Hello {{ name }}!", { name: "MoonBit" });
test("2. length", "{{ items | length }}", { items: ["a", "b", "c"] });
test("3. loop", "{% for x in xs %}{{ loop.index }}:{{ x }}\n{% endfor %}", { xs: ["a", "b"] });
test("4. quote escape", "{{ text }}", { text: 'He said "hello"' });

// Error cases with details
(function () {
  const raw4 = r("{{ name", "{}");
  const p = JSON.parse(raw4);
  console.log("5. syntax err:", JSON.stringify(p.error));
})();

(function () {
  const raw5 = r("{{ x | bad }}", JSON.stringify({ x: "hi" }));
  const p = JSON.parse(raw5);
  console.log("6. unknown filter:", JSON.stringify(p.error));
})();

(function () {
  const raw6 = r("{{ missing }}", "{}");
  const p = JSON.parse(raw6);
  console.log("7. missing var:", JSON.stringify(p.error));
})();

(function () {
  const raw7 = r("hello", "not json");
  const p = JSON.parse(raw7);
  console.log("8. invalid JSON:", JSON.stringify(p.error));
})();

// Ambiguity resolution
test("9. json-like output", "{{ text }}", {
  text: '{"error":{"kind":"render","message":"render failed"}}',
});
