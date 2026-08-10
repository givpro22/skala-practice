#!/usr/bin/env python3
"""템플릿3 서식을 그대로 입혀 보고서 docx를 만든다.

원본 docx를 열어 문단별 서식(pPr/rPr) 조각을 그대로 떠온 뒤, 새 본문을 그 조각에
끼워 넣는 방식이다. XML 전체를 다시 직렬화하지 않으므로 네임스페이스·테마·글꼴
설정이 원본 그대로 유지된다. 외부 패키지를 쓰지 않는다(표준 라이브러리만 사용).

사용법:
    python3 build_docx.py <source.md> <output.docx> [--template <template.docx>]

소스 문법은 references/template3-structure.md의 "소스 파일 포맷" 참조.
"""

import argparse
import os
import re
import sys
import zipfile

DEFAULT_TEMPLATE = os.path.expanduser("~/Desktop/닥스/코드이해_개인과제_템플릿3.docx")

P_RE = re.compile(r"<w:p\b[^>]*(?:/>|>.*?</w:p>)", re.DOTALL)
PPR_RE = re.compile(r"<w:pPr\b[^>]*(?:/>|>.*?</w:pPr>)", re.DOTALL)
RPR_RE = re.compile(r"<w:rPr\b[^>]*(?:/>|>.*?</w:rPr>)", re.DOTALL)
TEXT_RE = re.compile(r"<w:t\b[^>]*>(.*?)</w:t>", re.DOTALL)
NUMID_RE = re.compile(r'(<w:numId\s+w:val=")\d+(")')
SZ_RE = re.compile(r'<w:sz\s+w:val="(\d+)"')
NUM_STEP_RE = re.compile(r"^\s*\d+\.\s+\S")


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def para_text(xml):
    return "".join(TEXT_RE.findall(xml))


class Exemplars:
    """원본에서 역할별 문단 서식 조각을 뽑아 보관한다."""

    def __init__(self, body_xml):
        paras = P_RE.findall(body_xml)
        if not paras:
            raise SystemExit("템플릿에서 문단을 찾지 못했습니다. 원본 파일을 확인하세요.")

        self.roles = {}

        def prop(p, key):
            m = PPR_RE.search(p)
            return (m.group(0) if m else "").find(key) >= 0

        def outline(p):
            m = PPR_RE.search(p)
            if not m:
                return None
            o = re.search(r'<w:outlineLvl\s+w:val="(\d+)"', m.group(0))
            return int(o.group(1)) if o else None

        def size(p):
            m = RPR_RE.search(p)
            if not m:
                return None
            s = SZ_RE.search(m.group(0))
            return int(s.group(1)) if s else None

        for p in paras:
            txt = para_text(p).strip()
            has_num = prop(p, "<w:numPr")
            lvl = outline(p)
            sz = size(p)

            if "title" not in self.roles and lvl == 0 and sz and sz >= 40:
                self.roles["title"] = p
            elif "author" not in self.roles and lvl == 0 and sz and 26 <= sz <= 32:
                self.roles["author"] = p
            elif "chapter" not in self.roles and lvl == 1:
                self.roles["chapter"] = p
            elif "section" not in self.roles and lvl == 2:
                self.roles["section"] = p
            elif "bullet" not in self.roles and has_num:
                self.roles["bullet"] = p
            elif "blank" not in self.roles and not txt and not has_num:
                self.roles["blank"] = p
            elif "body" not in self.roles and txt and not has_num and lvl is None:
                self.roles["body"] = p

        missing = [r for r in ("title", "chapter", "section", "body", "bullet") if r not in self.roles]
        if missing:
            raise SystemExit("템플릿에서 다음 서식을 찾지 못했습니다: %s" % ", ".join(missing))
        self.roles.setdefault("author", self.roles["title"])
        self.roles.setdefault("blank", self.roles["body"])

        # 불릿에 쓸 수 있는 numId 목록 (목록이 바뀔 때마다 새 id를 쓰면 번호가 이어지지 않는다)
        self.bullet_ids = sorted({int(n) for n in re.findall(r'<w:numId\s+w:val="(\d+)"', body_xml)})
        if not self.bullet_ids:
            self.bullet_ids = [1]

    def build(self, role, text, num_id=None):
        src = self.roles[role]
        ppr = PPR_RE.search(src)
        ppr = ppr.group(0) if ppr else ""
        if num_id is not None:
            ppr = NUMID_RE.sub(r"\g<1>%d\g<2>" % num_id, ppr)
        rpr = RPR_RE.search(src.split("<w:pPr", 1)[-1].split("</w:pPr>", 1)[-1])
        rpr = rpr.group(0) if rpr else ""

        if not text:
            return "<w:p>%s</w:p>" % ppr

        runs = []
        for i, line in enumerate(text.split("\n")):
            if i:
                runs.append("<w:r>%s<w:br/></w:r>" % rpr)
            runs.append('<w:r>%s<w:t xml:space="preserve">%s</w:t></w:r>' % (rpr, esc(line)))
        return "<w:p>%s%s</w:p>" % (ppr, "".join(runs))


def parse_source(path):
    """소스 마크다운을 (role, text) 블록 목록으로 바꾼다."""
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")

    blocks = []
    buf = []
    in_code = False
    code = []

    def flush():
        if buf:
            blocks.append(("body", " ".join(x.strip() for x in buf).strip()))
            del buf[:]

    for raw in lines:
        line = raw.rstrip()

        if line.strip().startswith("```"):
            if in_code:
                blocks.append(("code", "\n".join(code)))
                del code[:]
                in_code = False
            else:
                flush()
                in_code = True
            continue
        if in_code:
            code.append(raw)
            continue

        if line.startswith("TITLE:"):
            flush()
            blocks.append(("title", line[len("TITLE:"):].strip()))
        elif line.startswith("AUTHOR:"):
            flush()
            blocks.append(("author", line[len("AUTHOR:"):].strip()))
        elif line.startswith("## "):
            flush()
            blocks.append(("section", line[3:].strip()))
        elif line.startswith("# "):
            flush()
            blocks.append(("chapter", line[2:].strip()))
        elif line.lstrip().startswith(("- ", "* ")):
            flush()
            blocks.append(("bullet", line.lstrip()[2:].strip()))
        elif NUM_STEP_RE.match(line):
            # "1. 로그인하면 ..." 같은 번호 단계는 한 줄이 한 문단이다.
            # 빈 줄 없이 이어 써도 서로 붙지 않게 여기서 끊는다.
            flush()
            blocks.append(("body", line.strip()))
        elif not line.strip():
            flush()
            blocks.append(("blank_hint", ""))
        else:
            buf.append(line)

    flush()
    if in_code:
        blocks.append(("code", "\n".join(code)))
    return blocks


def render(blocks, ex):
    out = []
    bullet_slot = 0
    prev = None

    for role, text in blocks:
        if role == "blank_hint":
            prev = role
            continue

        # 새 불릿 목록이 시작되면 다른 numId를 써서 이전 목록과 분리한다
        if role == "bullet" and prev != "bullet":
            bullet_slot = (bullet_slot + 1) % len(ex.bullet_ids)

        if role in ("chapter", "section") and out:
            out.append(ex.build("blank", ""))

        if role == "code":
            for line in text.split("\n"):
                out.append(ex.build("body", line if line.strip() else ""))
        elif role == "bullet":
            out.append(ex.build("bullet", text, num_id=ex.bullet_ids[bullet_slot]))
        else:
            out.append(ex.build(role, text))

        prev = role

    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("output")
    ap.add_argument("--template", default=DEFAULT_TEMPLATE)
    args = ap.parse_args()

    if not os.path.exists(args.template):
        sys.exit("템플릿을 찾을 수 없습니다: %s" % args.template)
    if not os.path.exists(args.source):
        sys.exit("소스 파일을 찾을 수 없습니다: %s" % args.source)

    with zipfile.ZipFile(args.template) as z:
        doc = z.read("word/document.xml").decode("utf-8")

    m = re.search(r"<w:body\b[^>]*>", doc)
    if not m:
        sys.exit("템플릿 구조가 예상과 다릅니다 (w:body 없음).")
    head = doc[: m.end()]
    body_xml = doc[m.end(): doc.rindex("</w:body>")]
    tail = doc[doc.rindex("</w:body>"):]

    sect = re.search(r"<w:sectPr\b.*?</w:sectPr>", body_xml, re.DOTALL)
    sect_xml = sect.group(0) if sect else ""

    ex = Exemplars(body_xml)
    new_body = render(parse_source(args.source), ex)

    new_doc = head + new_body + sect_xml + tail

    with zipfile.ZipFile(args.template) as zin, zipfile.ZipFile(
        args.output, "w", zipfile.ZIP_DEFLATED
    ) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == "word/document.xml":
                data = new_doc.encode("utf-8")
            zout.writestr(item, data)

    print("생성 완료: %s" % args.output)


if __name__ == "__main__":
    main()
