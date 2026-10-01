# mustache-ada

A [Mustache][] template engine in Ada — a small, strict subset aimed at code
generation, not HTML.  Pure Ada on the GNAT runtime; no C dependencies.  It is
the engine `hbnf` uses to turn a grammar's AST into the target language's
syntax, so the emitter never hardcodes a keyword.

[Mustache]: https://mustache.github.io/

## The subset

A template is text with `{{...}}` tags, rendered against a **context** — a
stack of scopes, each a tree of `Scalar` / `List` / `Map` values.  A name
lookup walks the stack from the top down, so a scope pushed by `{{#each}}` or
a partial both shadows and inherits its enclosing scopes.

| Tag | Meaning |
|---|---|
| `{{var}}` | print the scalar `var` (an unfilled or non-scalar name is an error) |
| `{{.}}` | the current element of a `{{#each}}` over scalars |
| `{{#each var}} … {{/each}}` | iterate a list, each element pushed as a scope |
| `{{#var}} … {{/var}}` | section: a list iterates, a map is pushed once, a non-empty scalar renders once |
| `{{^var}} … {{/var}}` | inverted: render iff `var` is absent or empty |
| `{{> partial}}` | include another loaded template, with the same stack |

Deviations from Mustache, on purpose:

- **No HTML escaping.**  `{{var}}` is raw — this engine emits code, not markup.
- **Strict, not silent.**  A missing `{{var}}`, a `{{#each}}` over a non-list,
  an unterminated section, and a key bound twice all raise `Template_Error`.
  Mustache renders them as empty; an emitter bug should not come out as a
  silently-mangled parser.
- **No whitespace/standalone-line trimming** and no triple-stache `{{{ }}}`.

Not yet supported (add when a caller needs them): lambda/partial values,
comments `{{! }}`, set-delimiter `{{= =}}`, and a token cache for partials.

## API

```ada
with Mustache;

--  Build a context:
Root : constant Mustache.Value_Access := Mustache.New_Map;
List : constant Mustache.Value_Access := Mustache.New_List;
Mustache.Insert (Root, "name", Mustache.New_Scalar ("foo"));
Mustache.Append (List, Mustache.New_Scalar ("alpha"));
Mustache.Append (List, Mustache.New_Scalar ("beta"));
Mustache.Insert (Root, "items", List);
Ctx : Mustache.Context := Mustache.New_Context (Root);

--  Render:
Mustache.Load ("templates");
Put (Mustache.Render ("struct", Ctx));      -- by name
Put (Mustache.Render_Text ("{{name}}", Ctx));  -- by raw text
```

`Value` is a discriminated record (`Scalar` | `List` | `Map`); builders return
`Value_Access`, so a context is a heap tree the caller drops when done.  The
engine is a short-lived tool (load templates, render, exit), so nothing is
deallocated.

## Building

```
gprbuild -P mustache.gpr -p -XLIBRARY_TYPE=static
gprinstall -P mustache.gpr -p -f -XLIBRARY_TYPE=static \
    --prefix=/usr --sources-subdir=include/mustache
```

Packaged for Alpine by the `ada-on-alpine` aports overlay as
`testing/mustache-ada`.

## License

ISC.  See `LICENSE`.
