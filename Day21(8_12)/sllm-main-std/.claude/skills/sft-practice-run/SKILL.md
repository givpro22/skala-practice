---
name: sft-practice-run
description: Qwen2.5-1.5B-Instruct 에 LoRA SFT 학습을 돌리고 Base vs SFT 평가를 실행해, 서브노트에 넣을 로그와 실행 화면 캡처를 만든다. "학습 돌려줘", "train_lora 실행", "파인튜닝 시작", "평가 돌려줘", "evaluate_model 실행", "Base vs SFT 비교해줘", "실습 실행해줘", "outputs 만들어줘", "평가 화면 캡처" 요청에 반드시 이 스킬을 쓴다. 학습을 다시 돌리거나 에폭·학습률을 바꿔 재학습하거나 평가만 다시 실행하는 후속 요청에도 같은 스킬을 쓴다. 학습 로그를 읽어 해석만 하는 요청은 sllm-evidence-mining 이 받는다 — 이 스킬은 실제로 프로세스를 띄우는 쪽이다.
---

# SFT 실습 실행

## 이 스킬이 만드는 것

```
outputs/training_log.json          loss, eval_loss, learning_rate, epoch, step
outputs/training_summary.json      최종 학습 설정과 결과
outputs/training_environment.json  장치, 라이브러리 버전
outputs/evaluation_results.jsonl   질문별 Base ↔ SFT 답변 대조
outputs/evaluation_summary.json    Keyword / Token F1 / 승패 집계
models/hr-qwen-lora/               adapter_config.json + adapter_model.safetensors

_workspace/logs/train.log          학습 stdout 원본 (tee)
_workspace/logs/eval.log           평가 stdout 원본 (tee)
_workspace/snapshots/*.png         실행 화면 캡처
```

`_workspace/logs/` 의 원본 로그를 지우지 마라. 스냅샷을 다시 굽거나 근거를 다시 읽는
작업이 전부 여기에 의존한다. `outputs/*.json` 은 요약이라 학습 중에 무엇이 찍혔는지는
로그에만 남는다.

## 1. 가상환경

readme 가 지정한 이름은 `sllm` 이고 프로젝트 루트에 만든다.

```bash
[ -x sllm/bin/python ] || python3.11 -m venv sllm
sllm/bin/python -m pip install -q --upgrade pip
sllm/bin/python -m pip install -q -r requirements.txt
```

`source activate` 를 쓰지 마라. 이 하네스의 Bash 호출은 매번 새 셸이라 activate 가
다음 호출까지 살아남지 않는다. `sllm/bin/python` 을 직접 부르면 그 문제가 없다.

디렉토리 존재만으로 판단하지 말고 `sllm/bin/python` 이 실행 가능한지로 본다. 중간에
끊긴 venv 는 디렉토리는 있고 인터프리터는 없다.

## 2. 학습

수업 권장 설정이다. 값을 바꾸려면 사용자에게 먼저 확인한다 — 설정이 바뀌면 서브노트에
적은 숫자가 전부 무효가 된다.

```bash
mkdir -p _workspace/logs
SFT_MAX_LENGTH=384 \
SFT_EPOCHS=2 \
SFT_LEARNING_RATE=1e-4 \
sllm/bin/python scripts/train_lora.py 2>&1 | tee _workspace/logs/train.log
```

Apple Silicon 은 FP32 LoRA 로 떨어져 **수십 분에서 몇 시간**이 걸린다. 반드시
`run_in_background: true` 로 띄우고, 기다리는 동안 근거 수집(`sllm-evidence-mining`)의
정적 부분을 진행한다. 학습이 끝날 때까지 아무것도 안 하고 대기하는 것이 가장 큰 낭비다.

읽을 수 있는 환경 변수: `SFT_MAX_LENGTH` `SFT_EPOCHS` `SFT_LEARNING_RATE`
`SFT_GRAD_ACCUM` `SFT_LORA_RANK` `SFT_LORA_ALPHA` `SFT_LORA_DROPOUT` `USE_QLORA`.
장치는 코드가 CUDA → MPS → CPU 순으로 자동 판별하므로 지정하지 않는다.

시작 직후 이 블록이 찍히는지 확인한다. 여기까지 나오면 설정이 먹은 것이다.

```
[Fine-tuning] Runtime
Device / Mode / Max length / Epochs / Learning rate
[Dataset]  Train records / Validation records
[Model]    Loading ...
[Fine-tuning] Training started
```

### 재학습

```bash
rm -rf models/hr-qwen-lora
```

기존 어댑터를 지우지 않고 다시 돌리면 이전 학습 결과 위에 덮이는지 새로 만드는지가
설정에 따라 갈린다. 재학습이면 먼저 지운다. 지우기 전에 `outputs/` 의 이전 결과를
`_workspace/prev_outputs_<설정요약>/` 으로 옮겨 둔다 — 설정을 바꿔 가며 비교한 기록
자체가 서브노트의 트러블슈팅 소재다.

## 3. 평가

학습이 끝나고 `models/hr-qwen-lora/adapter_config.json` 이 생긴 뒤에만 돈다.
평가 스크립트는 이 파일이 없으면 멈춘다.

```bash
sllm/bin/python scripts/evaluate_model.py 2>&1 | tee _workspace/logs/eval.log
```

같은 질문 20개에 Base 와 Base+LoRA 로 두 번 추론하므로 평가도 오래 걸린다.
이것도 백그라운드로 띄운다.

## 4. 실행 화면 캡처

가이드 2절 5번 항목이 요구하는 증빙이다. 두 경로가 있고 위쪽을 먼저 시도한다.

**(a) 데모 사이트** — `http://172.16.21.96:5173/`. 교수 담당 내부망이라 대개 닿지 않는다.
먼저 확인부터 한다.

```bash
curl -s -m 4 -o /dev/null -w '%{http_code}\n' http://172.16.21.96:5173/
```

`000` 이면 도달 불가다. 브라우저를 띄우지 말고 (b)로 간다. 닿으면 claude-in-chrome 으로
질문 선택 → 비교 실행 → Base/SFT 답변과 점수가 한 화면에 나온 상태를 캡처한다.

**(b) 실행 결과 화면** — 가이드가 명시적으로 허용한 대안이다.

```bash
python3 .claude/skills/sft-practice-run/scripts/term_shot.py \
    _workspace/logs/eval.log _workspace/snapshots/01_eval_summary.png \
    --title 'python scripts/evaluate_model.py' \
    --grep '\[Evaluation Summary\]'
```

`--grep` 은 그 패턴이 처음 걸리는 줄부터 끝까지 자른다. `--tail N` 은 마지막 N줄.
둘 다 안 주면 로그 전체가 한 장에 들어간다 — 학습 로그는 그러면 세로로 너무 길어진다.

찍을 만한 장면은 셋이다.

| 파일 | 무엇 | 인자 |
|---|---|---|
| `01_eval_summary.png` | 평가 집계, Base ↔ SFT 점수 대비 | `--grep '\[Evaluation Summary\]'` |
| `02_train_runtime.png` | 학습 시작 시 설정과 장치 | `--grep '\[Fine-tuning\] Runtime' --tail 24` |
| `03_train_done.png` | 학습 종료 loss, eval_loss | `--tail 20` |

### 로그를 손으로 고치지 않는다

`term_shot.py` 는 조판만 한다. 입력은 **실제로 실행해서 tee 로 받은 stdout** 이어야 한다.
숫자가 마음에 안 든다고 로그를 편집해서 굽는 순간 그건 캡처가 아니라 위조이고,
제출물에 들어가는 증빙이다. 결과가 아쉬우면 설정을 바꿔 다시 학습한다.

SFT 모델이 Base 에 지는 지표가 나와도 그대로 싣는다. 왜 그랬는지가 서브노트에서
가장 값나가는 대목이다.

## 5. 결과 확인

```bash
ls -la models/hr-qwen-lora/ outputs/
python3 -c "
import json
s=json.load(open('outputs/evaluation_summary.json'))
print(json.dumps(s, ensure_ascii=False, indent=2))"
```

어댑터 파일 2종(`adapter_config.json`, `adapter_model.safetensors`)과 outputs 4종이
다 있어야 다음 단계로 넘긴다. 하나라도 없으면 로그에서 예외를 찾아 보고한다.

## 에러 핸들링

| 증상 | 처리 |
|---|---|
| `pip install` 이 torch 에서 실패 | python3.11 인지 먼저 확인. 3.13 에서 휠이 없는 경우가 있다 |
| 학습이 시작 직후 죽음 | `_workspace/logs/train.log` 끝 40줄을 본다. 대개 메모리 아니면 데이터 형식 |
| MPS 에서 OOM | `SFT_MAX_LENGTH` 를 256 으로, `SFT_GRAD_ACCUM` 을 16 으로. **바꾼 값을 반드시 기록**한다 |
| 평가가 어댑터를 못 찾음 | 학습이 실제로 끝났는지 확인. `models/hr-qwen-lora/adapter_config.json` 존재가 조건 |
| 데모 사이트 미도달 | 재시도하지 말고 (b)로 간다. IP 가 바뀔 수 있다고 readme 에 적혀 있다 |
| 스냅샷이 0바이트 | `--headless=new` 로 바뀌었는지 확인. 이 환경에서는 `=old` 만 동작한다 |
| 학습이 너무 오래 걸림 | 죽이지 말고 사용자에게 경과와 남은 스텝을 보고한 뒤 판단을 받는다 |

## 후속 요청 처리

- "평가만 다시" → 학습을 건드리지 않는다. 어댑터가 그대로면 3단계만 돈다
- "에폭 늘려서 다시" → 이전 `outputs/` 를 `_workspace/prev_outputs_*/` 로 옮기고,
  어댑터를 지우고, 바뀐 설정으로 2단계부터. 두 결과의 비교가 곧 소재다
- "캡처만 다시" → 로그가 남아 있으므로 4단계만 돈다. 학습을 다시 돌리지 마라
