---
name: sllm-evidence-mining
description: sLLM SFT 실습의 근거를 실습 가이드 PDF, 노트북, 학습·평가 스크립트, 데이터셋, outputs 결과 파일에서 캐내 _workspace/01_evidence.md 로 정리한다. "근거 모아줘", "실습 내용 정리해줘", "학습 결과 분석해줘", "평가 결과 읽어줘", "무슨 데이터로 학습했는지 확인", "LoRA 설정 확인해줘", "노트북 뭐 했는지 정리" 요청에 이 스킬을 쓴다. 근거 파일을 갱신하거나 특정 절만 다시 채우는 후속 요청에도 같은 스킬을 쓴다. 실제로 학습·평가 프로세스를 띄우는 일은 sft-practice-run 이 한다 — 이 스킬은 이미 나온 결과를 읽는 쪽이다.
---

# sLLM 실습 근거 수집

## 원칙

**검증 가능한 사실만 모은다.** 해석하지 않고, 감상을 쓰지 않고, 문장을 다듬지 않는다.
그건 subnote-writer 의 몫이다. 여기서 문장을 예쁘게 만들면 집필자가 그 문장을 그대로
가져다 쓰고, 그러면 근거와 원고가 같은 말을 두 번 하게 된다.

**출처 없는 줄은 쓰지 않는다.** 모든 항목에 `파일:줄` 또는 `outputs/파일 → 키` 를
붙인다. 확인 못 한 것은 지우지 말고 `(미확인)` 으로 남긴다 — 지우면 집필자가
사실인 줄 알고 쓴다.

**숫자는 옮겨 적지 말고 파일에서 읽는다.** 평가 점수와 loss 는 전부 JSON 에 있다.
로그 화면을 눈으로 보고 받아 적으면 자리를 틀린다.

## 수집 순서

가이드부터 읽는다. 무엇을 써야 하는지 모르는 채로 코드를 읽으면 쓰지도 않을 것을
조사하게 된다.

1. `../sLLM_FineTuing_실습가이드.pdf` — 한 단계 위다. 2절이 서브노트 필수 항목,
   11절이 평가 지표 정의, 13절이 이해해야 할 핵심
2. `readme.md` — 디렉토리 구조와 수업 권장 설정
3. `outputs/*.json` — 실제로 나온 수치. 있으면 여기가 근거의 절반이다
4. `scripts/train_lora.py`, `scripts/evaluate_model.py` — 설정값과 지표 계산 방식
5. `dataset/**/*.jsonl` — 학습 데이터의 형태와 회사 고유 용어
6. 노트북 2종 — 1일차 소재

## 출력 형식

`_workspace/01_evidence.md` 를 A~H 여덟 절로 쓴다. **G 를 비우지 마라** — 트러블슈팅은
서브노트에서 배점이 붙는 항목인데 실행이 매끄러우면 소재가 없다고 넘기기 쉽다.
설치 충돌, 장치 판별, 소요 시간, 재학습 절차가 전부 소재다.

### A. 과제 요구사항

가이드 2절의 5개 항목을 원문 그대로 옮긴다. 이게 2일차 노트의 목차가 된다.
11절의 지표 정의(Keyword Score, Token F1, Hallucination)도 여기 넣는다.

### B. 실습 환경

```bash
sllm/bin/python -c "
import torch, transformers, peft, trl, platform
print('python     ', platform.python_version())
print('torch      ', torch.__version__)
print('mps        ', torch.backends.mps.is_available())
print('cuda       ', torch.cuda.is_available())
print('transformers', transformers.__version__)
print('peft       ', peft.__version__)
print('trl        ', trl.__version__)"
```

`outputs/training_environment.json` 이 있으면 그쪽이 우선이다. 학습이 실제로 돈
환경이 거기 찍혀 있고, 위 명령은 지금 시점의 환경이라 다를 수 있다.

### C. 데이터셋

```bash
wc -l dataset/training/*.jsonl dataset/evaluation/*.jsonl
python3 -c "
import json, collections
for p in ['dataset/training/hr_sft_train.jsonl','dataset/evaluation/hr_eval.jsonl']:
    rows=[json.loads(l) for l in open(p, encoding='utf-8')]
    print(p, len(rows))
    print('  keys:', sorted(rows[0].keys()))
    c=collections.Counter(r.get('category','-') for r in rows)
    print('  category:', dict(c))"
```

행 수, 메시지 3역할 구조, system instruction 원문, `category` 분포를 적는다.
회사 고유 용어(AURORA, BLUE-7, LYNX, HelpDesk 등)를 뽑아 두면 Keyword Score 가
무엇을 세는지 설명할 때 그대로 쓰인다.

### D. 1일차 노트북

- `knowledge_asset_demo_faiss_bge_m3.ipynb` — BGE-M3 임베딩, FAISS 인덱스 구축,
  Semantic Search, Knowledge Base 에 없는 질문에 대한 동작
- `peft_lora_parameter_compare_cache.ipynb` — LoRA 적용 전후 전체/학습가능 파라미터 수

노트북은 **실행 결과 셀(outputs)에 찍힌 실제 수치**를 옮긴다. 코드만 읽고 파라미터
수를 추정하지 마라.

```bash
python3 -c "
import json
nb=json.load(open('peft_lora_parameter_compare_cache.ipynb'))
for i,c in enumerate(nb['cells']):
    for o in c.get('outputs',[]):
        t=''.join(o.get('text',[])) or ''.join(o.get('data',{}).get('text/plain',[]))
        if t.strip(): print(f'--- cell {i} ---'); print(t[:600])"
```

출력이 비어 있으면 노트북이 실행 안 된 상태다. 그 사실을 `(실행 결과 없음)` 으로
적고, 필요하면 사용자에게 실행 여부를 확인한다.

### E. 학습 설정과 구조

`scripts/train_lora.py` 에서 LoRA rank, alpha, dropout, `target_modules` 목록,
장치별 프로파일(CUDA QLoRA / MPS FP32 / CPU FP32), SFTConfig 값을 뽑는다.
실제로 적용된 값은 `outputs/training_summary.json` 에 있으므로 둘을 대조한다.
코드 기본값과 실행값이 다르면 **둘 다 적는다** — 환경 변수로 무엇을 바꿨는지가 드러난다.

### F. 학습 실행 결과

```bash
python3 -c "
import json
log=json.load(open('outputs/training_log.json'))
print(type(log), len(log) if hasattr(log,'__len__') else '')
print(json.dumps(log[:3] if isinstance(log,list) else log, ensure_ascii=False, indent=2)[:800])
print('--- summary ---')
print(json.dumps(json.load(open('outputs/training_summary.json')), ensure_ascii=False, indent=2))"
```

loss 와 eval_loss 의 **첫 값, 마지막 값, 최저값과 그 스텝**을 적는다. 전체 곡선을
근거 파일에 다 옮기지 마라. 집필자가 다 넣으려 들고, 그러면 절 하나에 숫자가
스무 개씩 박힌다. 곡선이 필요하면 그림으로 넘긴다.

eval_loss 가 중간부터 올라가면 과적합 신호다. 그 스텝을 반드시 적는다.

### G. 평가 결과 — 이 절이 2일차 노트의 4번 항목이다

```bash
python3 -c "
import json
print(json.dumps(json.load(open('outputs/evaluation_summary.json')), ensure_ascii=False, indent=2))"
```

집계(Base wins / Fine-tuned wins / Ties, 양쪽 Keyword·Token F1·Total, Improvement)를
표로 옮긴다.

그 다음 `outputs/evaluation_results.jsonl` 에서 **대조 사례 2~3개**를 고른다. 고르는
기준은 점수 차가 큰 것이 아니라 **차이가 눈에 보이는 것**이다.

- SFT 가 회사 고유 규정(코드명, 승인 절차, 기한)을 답에 넣었고 Base 는 일반론을 편 사례
- Base 가 없는 규정을 지어낸 사례 (Hallucination)
- SFT 가 오히려 진 사례 — 있으면 반드시 하나 고른다. 이게 트러블슈팅 소재다

각 사례는 질문, Base 답변, SFT 답변, 두 점수를 나란히 적는다. 답변은 길므로
**핵심 문장만 잘라 옮기고 어디를 잘랐는지 표시**한다.

### H. 트러블슈팅 후보

실제로 겪은 것만 적는다. 겪지 않은 일반적 주의사항을 채우면 집필자가 안 겪은 일을
겪은 것처럼 쓰게 된다. 후보가 나오는 자리:

- `_workspace/logs/*.log` 의 경고와 예외 (`clean_up_tokenization_spaces`, 폴백 메시지)
- venv, 패키지 버전 충돌
- 장치 판별 결과와 그로 인한 속도
- 학습 소요 시간, 중단과 재개
- 설정을 바꿔 재학습했다면 그 전후 비교
- 데모 사이트 미도달

## 재호출 시

`_workspace/01_evidence.md` 가 이미 있으면 통째로 다시 쓰지 않는다. 요청받은 절만
갱신하고 그 절 끝에 `(갱신: 무엇을 추가했는지)` 를 한 줄 남긴다.

학습이 백그라운드로 도는 동안 A~E 를 먼저 채우고, 끝나면 F~H 를 채우는 것이
정상 순서다. F~H 를 기다리느라 A~E 를 미루지 마라.
