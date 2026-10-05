#!/usr/bin/env python3
"""Render README.md to index.html for the gh-pages landing page.

GitHub Pages normally does this with Jekyll, but Jekyll is disabled on the
gh-pages branch (via a .nojekyll file) because a ~462 MB tree of binary .apk
files makes the Jekyll build time out.  This is a deliberately minimal Markdown
renderer covering exactly the subset the README uses: ATX headings, paragraphs,
fenced and 4-space-indented code blocks, pipe tables, unordered lists, and
inline code/links/emphasis.  It is not a general Markdown engine.
"""
import html
import re
import sys


def esc(s):
    return html.escape(s, quote=False)


def inline(s):
    s = esc(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    return s


def render_table(rows):
    rows = [[inline(c.strip()) for c in r.strip().strip("|").split("|")] for r in rows]
    # Drop the separator row (| --- | --- |).
    rows = [r for r in rows if not all(re.fullmatch(r":?-{2,}:?", c) for c in r)]
    head, *body = rows
    out = ["<table><thead><tr>",
           "".join("<th>%s</th>" % c for c in head),
           "</tr></thead><tbody>"]
    for r in body:
        out.append("<tr>" + "".join("<td>%s</td>" % c for c in r) + "</tr>")
    out.append("</tbody></table>")
    return "\n".join(out)


def convert(text):
    lines = text.split("\n")
    out, para, i = [], [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("```"):
            if para:
                out.append("<p>%s</p>" % inline(" ".join(para)))
                para = []
            buf, i = [], i + 1
            while i < len(lines) and not lines[i].startswith("```"):
                buf.append(lines[i])
                i += 1
            i += 1
            out.append("<pre><code>%s</code></pre>" % esc("\n".join(buf)))
            continue
        m = re.match(r"^(#{1,6})\s+(.*)", ln)
        if m:
            if para:
                out.append("<p>%s</p>" % inline(" ".join(para)))
                para = []
            n = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (n, inline(m.group(2)), n))
            i += 1
            continue
        if ln.startswith("|"):
            if para:
                out.append("<p>%s</p>" % inline(" ".join(para)))
                para = []
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(lines[i])
                i += 1
            out.append(render_table(rows))
            continue
        if not ln.strip():
            if para:
                out.append("<p>%s</p>" % inline(" ".join(para)))
                para = []
            i += 1
            continue
        m = re.match(r"^(\s*)[-*]\s+(.*)", ln)
        if m:
            if para:
                out.append("<p>%s</p>" % inline(" ".join(para)))
                para = []
            out.append("<ul><li>%s</li></ul>" % inline(m.group(2)))
            i += 1
            continue
        if ln.startswith("    ") or ln.startswith("\t"):
            if para:
                out.append("<p>%s</p>" % inline(" ".join(para)))
                para = []
            buf = []
            while i < len(lines) and (lines[i].startswith("    ") or lines[i].startswith("\t")):
                buf.append(lines[i][4:] if lines[i].startswith("    ") else lines[i][1:])
                i += 1
            out.append("<pre><code>%s</code></pre>" % esc("\n".join(buf)))
            continue
        para.append(ln.strip())
        i += 1
    if para:
        out.append("<p>%s</p>" % inline(" ".join(para)))
    return "\n".join(out)


def main():
    body = convert(sys.stdin.read())
    print('<!doctype html><html><head><meta charset="utf-8">'
          '<meta name="viewport" content="width=device-width, initial-scale=1">'
          '<title>ada-on-alpine</title>'
          '<style>body{font-family:system-ui,sans-serif;max-width:52rem;margin:2rem auto;'
          'padding:0 1rem;line-height:1.55}code{background:#f6f8fa;padding:.1em .3em;'
          'border-radius:4px}pre{background:#f6f8fa;padding:1rem;overflow-x:auto}'
          'table{border-collapse:collapse}td,th{border:1px solid #d0d7de;padding:6px 12px}'
          'h1,h2{border-bottom:1px solid #d0d7de;padding-bottom:.3em}</style>'
          '</head><body>')
    print(body)
    print('</body></html>')


if __name__ == "__main__":
    main()
