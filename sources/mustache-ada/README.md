# mustache-ada

A complete [Mustache][] template engine in Ada: the whole core spec —
interpolation with HTML escaping, `{{{ }}}` / `{{& }}` raw tags, comments,
set-delimiter tags, sections and inverted sections, partials (with
standalone-line indentation), dotted names, and the implicit iterator
`{{.}}`.  It passes the [official Mustache spec][] suite (136 core tests),
and it is the engine `hbnf` uses to turn a grammar's AST into
target-language syntax.

Pure Ada on the GNAT runtime; no C dependencies.

[Mustache]: https://mustache.github.io/
[official Mustache spec]: https://github.com/mustache/spec

## Quick start

A template is text with `{{...}}` tags.  Build a **view** (a tree of
`Scalar` / `List` / `Map` values), then render a template against it.

```ada
with Mustache;  use Mustache;

V : Context := View;
Put (V, "name", "Ada");

declare
   L : constant Value_Access := New_List;
begin
   Append (L, New_Scalar ("alpha"));
   Append (L, New_Scalar ("beta"));
   Put (V, "items", L);
end;

Put_Line (Render ("Hello {{name}}!", V));
Put_Line (Render ("{{#items}}[{{.}}]{{/items}}", V));
```

prints `Hello Ada!` then `[alpha][beta]`.

## API overview

The package is `Mustache` (project `mustache.gpr`).  The API is deliberately
small:

- **Values** — `Value` is a discriminated record in three kinds:
  `New_Scalar (text)`, `New_List`, `New_Map`.  `Append (list, item)` grows a
  list; `Insert (map, key, item)` binds a key in a map (a duplicate key
  replaces the old one).
- **View** — `View` is a fresh `Context` (a scope stack).  `Put (view, key,
  value)` adds a string or a value to the top scope; `Push` / `Pop` stack
  scopes for sections and partials.
- **Render** — `Render (source, view)` renders a template string;
  `Render_File (name, view)` renders a template loaded by name.
- **Partials** — `Define (name, source)` registers a partial from a string;
  `Load (dir)` reads every `dir/*.tmpl`; `Reset` forgets them all.

## Mustache behaviour

| Tag | Meaning |
|---|---|
| `{{var}}` | HTML-escaped interpolation (`&` `<` `>` `"` `'`) |
| `{{{var}}}` / `{{&var}}` | raw interpolation |
| `{{#var}} … {{/var}}` | section: a list iterates, a map is pushed once, a truthy scalar renders once |
| `{{^var}} … {{/var}}` | inverted section: renders iff `var` is falsey |
| `{{! comment }}` | comment |
| `{{>partial}}` | include a partial |
| `{{=<< >>=}}` | change the delimiters |
| `{{.}}` | the current value (implicit iterator) |
| `a.b.c` | dotted-name lookup |

Truthiness follows the spec: `false`, `null`, the empty string, and an empty
list are falsey; everything else is truthy.  A missing name or partial
renders empty — never an error.  `Template_Error` is raised only for a
template that cannot be parsed (an unterminated tag, a section with no
closing tag, a bad delimiter change).

## Conformance

The six core files of the official Mustache spec suite are vendored under
`tests/spec/` and run by `tests/spec_check` (a small JSON parser drives the
engine directly).

```
gprbuild -P tests/check.gpr -p
./tests/mustache_check          # API smoke test
./tests/spec_check tests/spec   # official spec suite (136/136)
```

## Building

```
gprbuild -P mustache.gpr -p -XLIBRARY_TYPE=static
gprbuild -P mustache.gpr -p -XLIBRARY_TYPE=relocatable
gprinstall -P mustache.gpr -p -f -XLIBRARY_TYPE=static \
    --prefix=/usr --sources-subdir=include/mustache
```

Packaged for Alpine by the `ada-on-alpine` aports overlay as
`testing/mustache-ada`.  The man page is `mustache-ada(3)`, in the
`mustache-ada-doc` subpackage.

## License

ISC.  See `LICENSE`.
