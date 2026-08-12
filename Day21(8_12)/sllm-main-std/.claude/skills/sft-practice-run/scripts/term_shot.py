#!/usr/bin/env python3
"""
term_shot.py — 실제로 캡처된 터미널 로그를 그대로 PNG 로 굽는다.

    python3 term_shot.py <로그.txt> <출력.png> [--title 제목] [--tail N] [--grep 패턴]

실습 가이드 2절 5번 항목이 요구하는 것은 evaluate_model.py 실행 화면 캡처다.
데모 사이트(172.16.21.96:5173)가 내부망이라 닿지 않을 때 이 스크립트를 쓴다.

**입력은 반드시 실제로 실행해서 tee 로 받아 둔 stdout 이어야 한다.** 보기 좋으라고
손으로 고쳐 쓴 텍스트를 넣으면 그 순간 이건 캡처가 아니라 위조다. 숫자가 마음에
안 들면 로그를 고치는 게 아니라 학습을 다시 돌린다.

하는 일은 조판뿐이다.
  - ANSI 이스케이프 제거
  - 캐리지 리턴(\\r) 해소 — tqdm 진행바가 한 줄을 수백 번 덮어쓴 것을 마지막 상태만 남긴다
  - 터미널 배색으로 HTML 을 만들고 headless Chrome 으로 스크린샷
"""

import argparse
import html
import os
import re
import subprocess
import sys
import tempfile

ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]|\x1b\][^\x07]*\x07|\x1b[()][A-B]")

CHROME = os.environ.get(
    "CHROME_BIN", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)


def clean(raw: str) -> list[str]:
    """ANSI 를 벗기고 \\r 로 덮어쓴 줄을 마지막 상태로 접는다."""
    out = []
    for physical in raw.replace("\r\n", "\n").split("\n"):
        physical = ANSI.sub("", physical)
        # tqdm 은 같은 줄을 \r 로 계속 덮어쓴다. 마지막 조각이 최종 화면이다.
        if "\r" in physical:
            physical = physical.split("\r")[-1]
        out.append(physical.rstrip())
    # 끝의 빈 줄만 턴다. 중간 빈 줄은 원본 화면의 일부다.
    while out and not out[-1]:
        out.pop()
    return out


def build_html(lines: list[str], title: str, cols: int) -> str:
    body = "\n".join(html.escape(l) for l in lines)
    cap = html.escape(title)
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
  html,body {{ margin:0; padding:0; background:#12141a; }}
  .win {{ padding:0 0 14px 0; }}
  .bar {{ display:flex; align-items:center; gap:8px; height:30px;
          padding:0 12px; background:#23262f; border-bottom:1px solid #000; }}
  .dot {{ width:11px; height:11px; border-radius:50%; }}
  .r {{ background:#ff5f57; }} .y {{ background:#febc2e; }} .g {{ background:#28c840; }}
  .ttl {{ flex:1; text-align:center; color:#9aa0ac; font:12px -apple-system,sans-serif;
          margin-right:46px; }}
  pre {{ margin:0; padding:14px 16px 0 16px; color:#d6dae1;
         font-family:Menlo,'SF Mono',monospace; font-size:12.5px; line-height:1.5;
         white-space:pre; }}
</style></head><body>
  <div class="win">
    <div class="bar">
      <span class="dot r"></span><span class="dot y"></span><span class="dot g"></span>
      <span class="ttl">{cap}</span>
    </div>
    <pre>{body}</pre>
  </div>
</body></html>"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("out")
    ap.add_argument("--title", default="")
    ap.add_argument("--tail", type=int, default=0, help="마지막 N줄만")
    ap.add_argument("--grep", default="", help="이 패턴이 처음 걸리는 줄부터 끝까지")
    ap.add_argument("--cols", type=int, default=100)
    a = ap.parse_args()

    # newline="" 이 필수다. 기본 텍스트 모드는 universal newline 이라 읽는 시점에
    # \r 을 \n 으로 바꿔 버리고, 그러면 tqdm 진행바 한 줄이 수백 줄로 펼쳐진다.
    with open(a.log, encoding="utf-8", errors="replace", newline="") as f:
        lines = clean(f.read())

    if a.grep:
        pat = re.compile(a.grep)
        for i, l in enumerate(lines):
            if pat.search(l):
                lines = lines[i:]
                break
        else:
            print(f"!! --grep 패턴을 로그에서 찾지 못했습니다: {a.grep}", file=sys.stderr)
            return 1
    if a.tail:
        lines = lines[-a.tail :]

    if not lines:
        print("!! 로그가 비어 있습니다. 실행이 실패했는지 확인하세요.", file=sys.stderr)
        return 1

    # 캔버스 크기는 내용에 맞춘다. 잘리면 그건 캡처가 아니라 조각이다.
    widest = max((len(l) for l in lines), default=a.cols)
    w = min(max(widest, 60), 200) * 7.55 + 34
    h = len(lines) * 18.75 + 30 + 28

    title = a.title or os.path.basename(a.log)
    with tempfile.TemporaryDirectory() as tmp:
        page = os.path.join(tmp, "term.html")
        with open(page, "w", encoding="utf-8") as f:
            f.write(build_html(lines, title, a.cols))

        out = os.path.abspath(a.out)
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        if not os.access(CHROME, os.X_OK):
            print(f"!! Chrome 을 찾지 못했습니다: {CHROME}", file=sys.stderr)
            return 1

        # --headless=old 를 쓴다. Chrome 151 의 --headless=new 는 이 환경에서
        # 스크린샷 명령이 끝나지 않고 매달린다. handdrawn-diagram/render.sh 와 같은 이유다.
        subprocess.run(
            [
                CHROME, "--headless=old", "--disable-gpu", "--no-first-run",
                "--no-default-browser-check", "--hide-scrollbars",
                "--force-device-scale-factor=2",
                "--virtual-time-budget=3000",
                f"--window-size={int(w)},{int(h)}",
                f"--screenshot={out}",
                f"file://{page}",
            ],
            capture_output=True,
        )

    if not os.path.exists(out) or os.path.getsize(out) == 0:
        print(f"!! 스크린샷 실패: {out}", file=sys.stderr)
        return 1
    print(f"OK  {out}  ({len(lines)}줄, {os.path.getsize(out) // 1024}KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
