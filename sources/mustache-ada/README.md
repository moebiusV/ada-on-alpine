# mustache-ada

A [Mustache][] template engine in Ada — a small, strict subset aimed at code
generation, not HTML.  Pure Ada on the GNAT runtime; no C dependencies.  It is
the engine `hbnf` uses to turn a grammar's AST into the target language's
syntax, so the emitter never hardcodes a keyword.

[Mustache]: https://mustache.github.io/

## Quick start

A template is text with `{{...}}` tags.  You build a **context** (a tree of
`Scalar` / `List` / `Map` values), then render a template against it.

```ada
with Mustache;

Root : constant Mustache.Value_Access := Mustache.New_Map;
Item : constant Mustache.Value_Access := Mustache.New_List;

Mustache.Insert (Root, "name", Mustache.New_Scalar ("foo"));
Mustache.Append (Item, Mustache.New_Scalar ("alpha"));
Mustache.Insert (Root, "items", Item);

Ctx : Mustache.Context := Mustache.New_Context (Root);

Mustache.Load ("templates");
Put (Mustache.Render ("struct", Ctx));          -- by name
Put (Mustache.Render_Text ("{{name}}", Ctx));   -- by raw text
```

## API overview

The package is `Mustache` (project `mustache.gpr`):

- **Values** — `Value` is a discriminated record in three kinds:
  `New_Scalar (text)`, `New_List`, `New_Map`.  Builders return a
  `Value_Access` (a heap pointer); `Append (list, item)` grows a list,
  `Insert (map, key, item)` grows a map (a duplicate key raises
  `Template_Error`).  A value's kind is `Value_Kind` (`Scalar` | `List` |
  `Map`).
- **Context** — `Context` is a scope stack.  `New_Context (root)` makes a
  one-scope context; `Push` / `Pop` stack scopes for `{{#each}}` and
  partials.  A name lookup walks the stack from the top down, so an inner
  scope shadows (and inherits) its enclosing scopes.
- **Rendering** — `Load (dir)` reads every `dir/*.tmpl` (keyed by base name);
  `Render (name, ctx)` renders a loaded template, `Render_Text (source, ctx)`
  renders a raw string.
- **Errors** — `Template_Error` is raised for a missing template, an unfilled
  or non-scalar `{{var}}`, a `{{#each}}` over a non-list, an unterminated
  section, an unmatched closing tag, and a key bound twice.

## The subset

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

## Building

```
gprbuild -P mustache.gpr -p -XLIBRARY_TYPE=static
gprinstall -P mustache.gpr -p -f -XLIBRARY_TYPE=static \
    --prefix=/usr --sources-subdir=include/mustache
```

Packaged for Alpine by the `ada-on-alpine` aports overlay as
`testing/mustache-ada`.  The man page is `mustache-ada(3)`, in the
`mustache-ada-doc` subpackage.

## License

ISC.  See `LICENSE`.
