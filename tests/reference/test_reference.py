"""Tests for the SSGBerk reference assets and reference HTML (spec 005)."""
import hashlib
import os
import re
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PLAN = os.path.join(ROOT, "docs", "specs", "005-reference-site-design", "plan.md")
REF = os.path.join(ROOT, "reference")
MAKE_PNG = os.path.join(ROOT, "tools", "make_reference_png.py")
PNG_SHA256 = "13618b33e7f8c4ba12e2a638f70a635643b9a8657c9f9da03f3bfc68fd2374b3"


def read_bytes(path):
    with open(path, "rb") as fh:
        return fh.read()


def plan_text():
    return read_bytes(PLAN).decode("utf-8")


def fenced_after(heading, lang):
    """First ```<lang> block after the line starting with `heading`."""
    text = plan_text()
    start = text.index("\n" + heading)
    m = re.compile(r"^```%s\n(.*?)^```$" % lang, re.S | re.M).search(text, start)
    assert m, "no %s block after %s" % (lang, heading)
    return m.group(1)


def png_chunks(data):
    pos, out = 8, []
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        out.append((ctype, data[pos + 8:pos + 8 + length]))
        pos += 12 + length
    return out


class ReferenceTest(unittest.TestCase):
    def test_css_is_literal(self):
        expected = fenced_after("## Stylesheet", "css").encode("utf-8")
        self.assertTrue(expected.endswith(b"\n"))
        self.assertEqual(read_bytes(os.path.join(REF, "assets", "ssgberk.css")), expected)

    def test_css_rules(self):
        css = read_bytes(os.path.join(REF, "assets", "ssgberk.css")).decode("utf-8")
        for bad in ("@import", "url(", "-webkit-", "-moz-"):
            self.assertNotIn(bad, css)
        self.assertRegex(css, r"\A/\*[^\n]*\*/\n:root \{\n")
        self.assertNotIn("\r", css)

    def test_png_header(self):
        data = read_bytes(os.path.join(REF, "assets", "ssgberk.png"))
        self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
        chunks = png_chunks(data)
        self.assertEqual([c[0] for c in chunks], [b"IHDR", b"IDAT", b"IEND"])
        w, h, depth, ctype, comp, filt, inter = struct.unpack(">IIBBBBB", chunks[0][1])
        self.assertEqual((w, h, depth, ctype, comp, filt, inter), (64, 64, 8, 2, 0, 0, 0))

    def test_png_generator_deterministic_and_matches_committed(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = os.path.join(tmp, "a.png"), os.path.join(tmp, "b.png")
            for out in (a, b):
                r = subprocess.run([sys.executable, MAKE_PNG, out])
                self.assertEqual(r.returncode, 0)
            self.assertEqual(read_bytes(a), read_bytes(b))
            self.assertEqual(read_bytes(a), read_bytes(os.path.join(REF, "assets", "ssgberk.png")))
            self.assertEqual(hashlib.sha256(read_bytes(a)).hexdigest(), PNG_SHA256)
            self.assertEqual(png_chunks(read_bytes(a))[0][1][:8], struct.pack(">II", 64, 64))

    def test_png_pixels(self):
        import zlib
        data = read_bytes(os.path.join(REF, "assets", "ssgberk.png"))
        raw = zlib.decompress(png_chunks(data)[1][1])
        self.assertEqual(len(raw), 64 * (1 + 64 * 3))
        colours = ["2f5bd3", "f2f4f8", "1d2330", "d8dde7"]
        for y in range(64):
            row = raw[y * 193:(y + 1) * 193]
            self.assertEqual(row[0], 0)
            self.assertEqual(row[1:], bytes.fromhex(colours[y // 16]) * 64)

    def test_reference_html_literal(self):
        post = fenced_after("### Post page", "html")
        index = fenced_after("### Index (N=3)", "html")
        main = fenced_after("### 404 page", "html")
        old_main = re.search(r"<main class=\"site-main\">\n.*?</main>\n", post, re.S).group(0)
        page404 = post.replace(old_main, main + "\n" if not main.endswith("\n") else main)
        page404 = page404.replace(
            "<title>Post 1 amber raven | SSGBerk Reference</title>",
            "<title>Page not found | SSGBerk Reference</title>")
        for name, expected in (("post", post), ("index", index), ("404", page404)):
            path = os.path.join(REF, "html", name + ".html")
            self.assertTrue(os.path.exists(path), path)
            self.assertEqual(read_bytes(path), expected.encode("utf-8"), name)
        got = read_bytes(os.path.join(REF, "html", "404.html")).decode("utf-8")
        self.assertIn('<section class="not-found">', got)
        self.assertIn("<title>Page not found | SSGBerk Reference</title>", got)
        self.assertNotIn("aria-current", got)


if __name__ == "__main__":
    unittest.main()
