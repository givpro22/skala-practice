# 근거 모음 — SKALA 5주차 Agile & MSA 개인과제

수집: 2026-08-10 / 수집 대상 5소스
팀 저장소는 `git clone --depth 1 https://github.com/siamin20/skala-msa-customs` 로 확보.

---

## A. 과제 범위 (교수님 코멘트)

출처: `2026-08-10_171407.txt`

> "개인 과제에는 여러분들이 이틀 동안 (…) msa 공부를 하면서 느낀 것 (…) 템플릿 1번을 쓰셔서
> 코드 정리하시면 되고 아니면 플로우 정리해도 되고"

> "제가 백엔드는 코드 이해하고 활용만 하면 된다고 그랬죠? 그럼 msa가 어떤 의도이고 진짜
> 서비스가 분할되어 있네요 (…) 잘 연결해야 되잖아요. 그러니까 유레카 라는 것도 필요하고
> 카프카 API 게이트웨이 필요한데 이게 뭔지 알겠다. **이걸 깊게 파지는 않겠지만 필요한
> 이유는 알겠어. 충분해요.**"

**함의 (톤의 상한선):**
- 쓸 것 → "왜 이 부품이 필요한가"를 서비스 분할이라는 사실에서 도출한 서술
- 쓰지 말 것 → Eureka 하트비트 주기, JWK 서명 검증 절차, Kafka 파티션 전략 같은 내부 메커니즘
- 실습 가이드도 같은 선을 긋는다: "제공된 백엔드 코드를 한 줄씩 읽으며 이해하려는 시도는
  이번 실습 범위를 벗어난 것이며, 이해가 안 되는 것이 정상입니다."
  (`Agile_MSA_실습_가이드_수정 (1).pdf` §2)

---

## B. 아키텍처 사실

| 항목 | 값 | 출처 |
|---|---|---|
| 서비스 총 컨테이너 | 10개 | 팀 readme "검증" 절 |
| Eureka 등록 서비스 | 7개 | 팀 readme "검증" 절 |
| Kafka 토픽 | 2개 | 팀 readme "검증" 절 |
| vue-frontend | 3000 (compose 아님, `npm run dev`) | 팀 readme 포트표 |
| api-gateway | 8080 — **단일 진입점**. 직접 열면 401 | 팀 readme 포트표 |
| user-service | 8081 | 〃 |
| course-service | 8082 | 〃 |
| enrollment-service | 8083 | 〃 |
| payment-service | 8084 | 〃 |
| recommend-service | 8085 (Python/FastAPI, `/docs`) | 〃 |
| eureka-server | 8761 (대시보드) | 〃 |
| auth-server | 9000 | 〃 |
| kafka | 9092 (KRaft 모드) | `docker-compose.yml:31-48` |
| mariadb | 3379:3306, DB `lecture_db` | `docker-compose.yml:9-18` |
| 기동 순서 | MariaDB/Kafka → Eureka → Auth → Gateway+4서비스 → Recommend | 팀 readme, `depends_on` |
| Eureka 등록 방식 | 모든 서비스에 `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://eureka-server:8761/eureka/` 환경변수 | `docker-compose.yml:94,119,145,170,196,224` |
| Kafka 연결 | enrollment·payment만 `SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092` | `docker-compose.yml:199,227` |
| 수정 금지 영역 | eureka-server / auth-server / api-gateway | 진행 가이드 PDF, 팀 readme |
| 인프라 배포 | auth-server·api-gateway는 소스 없이 `infra-images.tar` 이미지로만 | 진행 가이드 PDF |

### Gateway 라우팅 규칙 (원문)

컨테이너 안 jar에서 꺼낸 실제 설정. 출처: `_workspace/06_qa_report.md` 판정 1

```yaml
# lecture-gateway:/app/app.jar!/BOOT-INF/classes/application.yml
- id: enrollment-service
  uri: lb://enrollment-service
  predicates:
    - Path=/api/enrollments/**
  filters:
    - RewritePath=/api/enrollments/(?<segment>.*), /api/enrollments/${segment}
```

- `lb://` = Eureka에서 이름으로 찾아 로드밸런싱. **IP·포트가 설정에 없다.**
- `Path=/api/{서비스}/**` prefix 방식 → 하위 신규 엔드포인트는 Gateway 재빌드 불필요 (실증됨)
- Gateway의 `JwtAuthenticationFilter` 가 JWT에서 `X-User-Id`/`X-User-Email`/`X-User-Role` 주입

---

## C. 흐름 (이음매별)

### C-1. 전체 시나리오
로그인(OAuth2 2단계) → 검토 서비스 목록 조회 → 통관 검토 의뢰(PENDING) →
수수료 결제 → **Kafka** → 의뢰 확정(ACTIVE) → 관세사 추천

### C-2. 동기 호출 (서비스 → 서비스)
- `enrollment-service` → `course-service` `internal/exists/{id}` — 검토 서비스 존재 확인
  (`CourseServiceClient.java:25`)
- `enrollment-service` → `course-service` `internal/{id}` — 결제 금액을 실제 `price`에서 조회
  (`CourseServiceClient.java:47`)
- `enrollment-service` → `course-service` `internal/{id}/enrollment-count` — 처리 건수 증가
  (`CourseServiceClient.java:98`)
- `recommend-service` → `course-service` `internal/recommend`
  (`recommend-service/app/client/course_client.py:28`)
- 호출 방식: `@LoadBalanced WebClient.Builder` — **주소가 아니라 서비스 이름으로 부른다**
  (`WebClientConfig.java:15-19`, 인증 필터 없음)

### C-3. 비동기 (Kafka) — 이 보고서의 핵심 이음매
- 발행: `PaymentKafkaProducer.publishPaymentCompleted()` → 토픽 `payment.completed`
  (`payment-service/.../kafka/PaymentKafkaProducer.java`)
  - 키는 `String.valueOf(event.getUserId())`
  - payload: `paymentId, userId, courseId, status`
  - **개발 단계라 `.get(10, TimeUnit.SECONDS)` 로 동기 대기** — 발행 성공 여부를 즉시 보려고
- 수신: `EnrollmentKafkaConsumer.handlePaymentCompleted()`
  (`enrollment-service/.../kafka/EnrollmentKafkaConsumer.java`)
  - **`Map<String, Object>` 로 받는다.** 주석 원문: "payment-service 쪽은 JsonSerializer +
    type header 미포함으로 이벤트를 발행하므로, 여기서는 특정 DTO 타입으로 바로 받지 않고
    Map<String, Object> 로 받아 처리한다."
  - 처리: `enrollmentService.activateEnrollment(userId, courseId)` → PENDING → ACTIVE
  - 이후 `enrollment.completed` 발행 → recommend-service
- 실측 전환 시간: **결제 후 1초 내** (`_workspace/06_qa_report.md` 판정 3)

### C-4. 결제가 상태를 직접 바꾸지 않는다 (팀이 명시적으로 설계한 지점)
`EnrollmentService.java` 주석 원문 (팀 저장소):

> "결제 성공 시 payment-service가 payment.completed 이벤트를 발행하고, 그 이벤트를 받아
> `activateEnrollment(Long, Long)` 이 상태를 ACTIVE로 바꾼다. **즉 이 메서드는 상태를
> 직접 바꾸지 않는다.**"

---

## D. 팀이 원본에서 바꾼 것

원본 `msa-lecture/` ↔ 팀 저장소 `diff -rq` 결과 기준.

| 원본 (온라인 강의 수강신청) | 팀 (CustomsBridge 통관 중개) | 파일 |
|---|---|---|
| 강사 INSTRUCTOR | 관세사무소 | `instructorId` 재사용 |
| 수강생 STUDENT | 수입기업 담당자 | — |
| 과목 등록 | 검토 서비스 등록 | `title` |
| 수강료 | 검토 수수료 | `price` |
| 수강신청 | 통관 검토 의뢰 | Enrollment |
| 수강권한 노출 | 의뢰 확정 → 관세사 연락처 열람 | status `ACTIVE` |
| `Category { BACKEND, FRONTEND, DEVOPS, DATA_SCIENCE, MOBILE, SECURITY, DATABASE, OTHER }` | `{ ELECTRONICS, CHEMICAL, TEXTILE, FOOD_AGRI, METAL, OTHER }` | `Course.java:59-70` |
| 접수 즉시 자동 결제 (`requestPayment(... 99000)`) | **결제 분리** — `POST /enrollments/{id}/pay` 신설 | `EnrollmentService.java` |
| 결제 금액 하드코딩 `99000` | course-service에서 조회한 실제 `price` | 〃 |
| recommend: 과목 추천 | recommend: **HS코드 AI 품목분류 + 관세사 추천** | `hs_classifier.py` (신규) |

**DB 스키마 변경 0, 신규 엔티티 0.** (팀 readme "도메인 매핑" 절)

결제를 분리한 이유 (`EnrollmentService.java` 주석 원문):
> "접수 즉시 자동 결제하면 PENDING 상태가 화면에 드러나지 않아 '접수 → 결제 → 확정'을
> 보여줄 수 없기 때문이다."

---

## E. 숫자

**E절은 시간 순으로 두 층이다.** 아래를 섞으면 결론이 반대로 나온다.

| 층 | 시각 | 커밋 | 무엇 |
|---|---|---|---|
| 1층 | 08-10 17:19 / 17:29 | `072db33` / `95932b6` | Sprint1·2 완료 + readme 작성. 임계값 0.85 자동 확정 설계 |
| 2층 | 08-10 21:23 | `4dc34a9` | 하이브리드 검색 + 관세청 실세율. **자동 확정 제거** |
| 2층 | 08-10 22:40 | `b50850b` | 검색 실패와 분류 애매함 구분. torch 의존성 추가 |

`git log --oneline -- readme.md` → 마지막이 `95932b6`. **readme는 2층 이후 갱신되지
않았다.** 저장소 안에서 readme와 코드가 어긋나 있고, 어긋난 항목이 셋이다 —
자동 확정, 임계값 측정표, 세율 하드코딩 22건. 아래에서 각각 두 층을 다 적는다.

### E-1. 두 층에서 변하지 않은 값 (그대로 써도 되는 것)

| 항목 | 값 | 출처 |
|---|---|---|
| HS부호 데이터 | 관세청 **12,469행** (`app/data/hs_codes.csv` 12,470줄 = 헤더+12,469) | 파일 실측 |
| 어휘 색인 / 질의 | 0.12초 / 0.08ms | readme:195 |
| 기본 확신도 임계값 | **0.85** | `app/config/settings.py:33` `hs_confidence_threshold: float = 0.85` |
| 임계값 환경변수 | `HS_CONFIDENCE_THRESHOLD` | `docker-compose.yml:258` `${HS_CONFIDENCE_THRESHOLD:-0.85}` |
| 임계값 재적용 | 환경변수 변경 후 재시작 **11초**, 재빌드 없음 | readme:205-206 |
| QA 결과 | 통과 35 / 실패 0 / 미검증 4 | `_workspace/06_qa_report.md` |
| 카테고리 동기화 지점 | Java·Python·Vue·SQL **7개 지점** | readme |
| 입력 구체성 효과 | `냉동 새우` 0.5 ↔ `냉동 흰다리새우` 0.9966 | readme:249 |

### E-2. 자동 확정 — 1층에는 있었고 2층에서 **제거됐다**

**1층 (readme·초기 설계).** 확신도 ≥ 0.85면 코드 확정, 미만이면 관세사 연결.
`의사결정_기록.md:193` 이 이 설계를 `원래 설계` 로 명시한다.

**2층 (현재 코드).** AI 단독 확정이 설계에서 빠졌다. 확인한 자리 넷.

- `recommend-service/app/service/hs_classifier.py:981-982`
  ```python
  # 하위 호환용. 이제 항상 False다 — AI 단독 확정을 설계에서 뺐다.
  "autoConfirmed": False,
  ```
- `recommend-service/app/model/schemas.py:177-181` — `autoConfirmed: bool = False`,
  주석 `하위 호환용. **항상 False다** — AI 단독 확정을 설계에서 뺐다.`
- `hs_classifier.py:895-916` `confidence_level()` — 등급만 매긴다.
  `NONE`(후보 없음) → `TIE`(1·2위 동점) → `HIGH`(확신도 ≥ 임계값) → `LOW`
- `recommend-service/app/router/recommend_router.py:50` — `if result["level"] != "HIGH":`
  일 때 관세사 목록을 붙인다. 확정은 사용자가 한다.
- `의사결정_기록.md:16` 의사결정 #5 `자동 확정 | **제거** | 오답 자동확정 실측`,
  본문 `:191-230`

**임계값이 지금 하는 일이 남아 있다.** `CONFIDENCE_THRESHOLD` 는 죽지 않았고
`hs_classifier.py:914` 에서 HIGH 등급 판정에 쓰인다. 그래서 환경변수를 바꾸면
지금도 라우팅이 갈리는데, 갈리는 것은 `자동 확정 ↔ 관세사 검토` 가 아니라
**관세사 카드가 붙는가 아닌가**다. 발표용 11초 시연은 그대로 성립한다.

**(주의) 옛 주석이 두 곳에 남아 있다.** 코드는 바뀌었는데 주석만 안 바뀌었다.
`hs_classifier.py:50` 과 `docker-compose.yml:255` 둘 다 아직
`이 값 이상이면 자동 확정` 이라고 적혀 있다. 주석을 근거로 쓰면 안 된다.

**동점(TIE)이 흔하다.** `hs_classifier.py:880-892` `is_tie()` 주석 —
현실적 질의 75건 중 **54건(72%)이 1·2위 동점**. 커밋 `4dc34a9` 메시지도 같은 값.

### E-3. 임계값 측정 — 22건 표(1층)와 75건 표(2층)

**1층. 데모 22건** (readme:212-220). 원문 그대로.

| 임계값 | 자동확정 | 그중 정답 | 고확신 오답 |
|---|---|---|---|
| **0.85** (기본) | 3/22 | 3/3 | **0** |
| 0.60 | 4/22 | 4/4 | **0** |
| 0.50 | 11/22 | 6/11 | **5** ← 절벽 |
| 0.25 | 21/22 | 10/21 | **11** |

자동 처리율 데모 22건 중 3건(14%) — readme:249.

**2층. 현실적 질의 75건** (`의사결정_기록.md:205-208`). 표본이 더 크고 더 나중이다.

| 임계값 | 자동확정 | 정확도 |
|---|---|---|
| 0.85 | 4건 (5.3%) | 3/4 (75%) ← 오답 발생 |
| 0.90 | 3건 (4.0%) | 3/3 (100%) |

검수자가 인용한 수치와 **일치한다. 확인 완료.**

**왜 두 표가 반대인가 — 테스트셋이 편향돼 있었다.** 이게 이번 실습의 제일 좋은 소재다.

- 자동 생성 400건(공식 품목명 토큰을 섞은 것): 소호 1위 **58.0%**, 오답 자동확정 **0건**
- 현실적 질의 75건(T1 공식명 / T2 상거래 / T3 구어체): 소호 1위 **24.0%**,
  확신도 0.888에서 오답 자동확정 **1건**
- 출처: `의사결정_기록.md:114-140`, `:410-412`, 커밋 `4dc34a9` 메시지
- 팀이 남긴 교훈 원문 (`의사결정_기록.md:140`):
  `테스트셋이 편향되면 정확도만이 아니라 **안전성 판단까지 틀린다.**`

**오답 사례 — LED 모듈.** 확신도 **0.888**, 정답 **8541.41**(발광다이오드, 소자),
판정 **8539.51**(LED 램프, 조명기구). 서로 다른 호다.
출처: `의사결정_기록.md:197-201`, `hs_classifier.py:899-904`, 커밋 `4dc34a9` 메시지.

**0.90으로 올리면?** 오답은 사라지지만 자동 확정이 75건 중 3건(4%)뿐이라
표본 3건으로 안전하다고 말할 수 없다 (`의사결정_기록.md:210`). 호 단위로 봐도
정확도 90%를 만들면 커버리지가 13%로 떨어진다 — 10건 중 9건 정답,
신뢰구간 60~98% (`:211`). 그래서 임계값을 올리는 대신 자동 확정 자체를 뺐다.

**확신도는 확률이 아니다** (`의사결정_기록.md:213-223`).

| 구간 | 건수 | 평균 확신도 | 실제 정확도 |
|---|---|---|---|
| 0.5~0.6 | 180 | 0.503 | **26.7%** |
| 0.7~0.8 | 14 | 0.757 | 100% |
| 0.9~1.0 | 110 | 0.968 | 100% |

**ECE 0.159.** 자동 400건 중 45%가 0.50~0.51에 뭉쳤고 그 구간 실제 정확도는 26.7%다.
원인은 산식이다 — 완전 동점이면 `s1 × (1 − 0.5×1³)` 이 정확히 0.5가 된다.
확신도 50%가 아니라 **못 고르겠다**는 뜻이라 `TIE` 상태로 분리했다.

### E-4. 확신도 산식 — 두 커밋에서 **바뀌지 않았다**

`hs_classifier.py:552-560` (기존 근거의 `554-581` 은 줄이 밀린 것이라 여기서 정정).

```python
s1 = candidates[0]["score"]
s2 = candidates[1]["score"] if len(candidates) > 1 else 0.0
penalty  = GAP_DISCOUNT * (s2 / s1) ** GAP_EXPONENT      # 0.5, 지수 3.0
evidence = min(1.0, candidates[0].get("matchedConcepts", MIN_CONCEPTS) / MIN_CONCEPTS)
return round(max(0.0, s1 * (1 - penalty) * evidence), 4)
```

- `MIN_CONCEPTS = 2` — `hs_classifier.py:67`.
  **`git log -S "MIN_CONCEPTS"` 결과가 `072db33` 한 건뿐이다.** 즉 근거 개수 항은
  Sprint 2 안에서 이미 들어갔고 이번 두 커밋과 무관하다. `"구리선"` 이 오답을
  확신도 1.0으로 확정한 사례를 막은 것도 1층 사건이다 (readme:202).
- `GAP_DISCOUNT = 0.5`, `GAP_EXPONENT = 3.0` — `hs_classifier.py:59-60`
- 산식 주석 원문 (`:541`): `점수가 높아도 2위가 비슷하면 그건 '확신'이 아니라 '애매함'이기 때문이다.`
- **바뀐 것은 산식이 아니라 이 값을 무엇에 쓰는가다.** 1층에서는 임계값과 비교해
  확정 여부를 갈랐고, 2층에서는 등급으로만 환산한다.

### E-5. 의존성 — 이제 0이 **아니다**

1층 readme:194 는 `의존성 추가 0 — 표준 라이브러리만. scikit-learn 쓰지 않습니다` 라고
적었다. 커밋 `b50850b` 가 이를 깼다. `recommend-service/requirements.txt:22-24`:

```
--extra-index-url https://download.pytorch.org/whl/cpu
torch==2.6.0
sentence-transformers==3.3.1
```

**왜 넣었나** (`requirements.txt:12-14` 주석 원문, 호 Top3 기준 / 현실적 질의 75건):

| | 호 Top3 | T3(구어체) |
|---|---|---|
| 어휘 단독 | 57.3% | 33% |
| 하이브리드 | 69.3% | 48% |

같은 파일 `:11` — `어휘 매칭만으로는 구어체 질의가 잡히지 않는다.`

**이미지 크기는 실측이 아니라 팀이 적어 둔 추정이다.** 저장소 전체에서 2.5GB가
나오는 자리는 두 곳뿐이고 둘 다 서술이다.

- `requirements.txt:16-17` — `⚠ 이미지 크기가 크게 늘어난다 (약 200MB → 2.5GB).`
  `torch(CPU 전용) + 모델 가중치(~470MB) 때문이다.`
- `의사결정_기록.md:404` — `도커 | torch 반영 시 이미지 200MB → 2.5GB. **반영 여부 미결정**`

다만 `recommend-service/Dockerfile:5-6` 이 `COPY requirements.txt .` +
`RUN pip install --no-cache-dir -r requirements.txt` 이고 `docker-compose.yml:241-243`
이 그 Dockerfile로 빌드하므로, **지금 상태로 빌드하면 실제로 늘어난다.**
(미확인) 빌드 실측 로그는 저장소에 없다. 보고서에는 `늘었습니다` 가 아니라
`늘어난다고 팀이 적어 뒀습니다` 쪽으로 써야 사실에 맞다.

**없어도 돌아간다.** `hs_classifier.py:936-949` 가 `dense_rerank.available()` 이
False면 어휘 단독으로 폴백하고, 재순위 실패도 `except` 로 받아 어휘 결과를 쓴다.
`requirements.txt:18-19` — `이미지 크기를 우선하려면 아래 두 줄을 주석 처리하면 된다.`

### E-6. 검색 방식 — 어휘 단독 → 하이브리드 (`4dc34a9`)

- 모델 `intfloat/multilingual-e5-small` — `app/service/dense_rerank.py:33`
- 융합 가중치 α=0.7 — `dense_rerank.py:37` `ALPHA_LEX = float(os.getenv("HS_ALPHA_LEX", "0.7"))`
- 소호 1위 기준 75건: 어휘 단독 **24.0%** → 하이브리드 **38.7%**
  (`의사결정_기록.md:135-136`, `hs_classifier.py:923`)
- T3(구어체 27건) 소호 1위: 어휘 단독 **0.0%** → 하이브리드 **14.8%** (`:135-136`).
  팀 표현 (`:138`): `어휘 단독은 구어체 27건 중 0건을 맞혔다.`
- BM25 전면교체는 **기각**. 소호 1위 50.0% → 27.3% (`:99-104`). 사유 (`:108-110`):
  HS 품목명은 문서가 아니라 분류 라벨이라 길이 정규화가 해롭다. 설명이 길수록
  정밀하게 특정된 항목인데 길이로 벌점을 주면 `기타`·`그 밖의 것` 이 정답을 밀어낸다.
- 영문 품목명 12,469행이 데이터에 전량 있는데 안 쓰고 있었다 (`:145`). 한·영 혼합 색인.
- e5-base(768d)와 e5-small(384d)이 동일 성능 70.7% → small 유지, 인덱싱 3배 빠름 (`:154`)
- 벡터 DB 미도입 — 5,613개 × 384차원이면 numpy 행렬곱 1ms 미만 (`:156`)
- 지연 (`:160-165`): 어휘 단독 중앙값 0.09ms / p95 0.31ms, 하이브리드 중앙값 **6.15ms** /
  p95 19.69ms / **콜드스타트 약 9.5초**(최초 1회). 68배지만 절대값이 6ms라 체감 불가

**(미확인) 호 Top3 최종 수치가 문서마다 다르다.** `의사결정_기록.md:149-152` 는
소호명만 68.0% → 한·영 혼합 **70.7%** 로 적고, `hs_classifier.py:942` 주석도 70.7%다.
반면 `의사결정_기록.md:16`(#4)·`:176`·`:398` 과 `requirements.txt:14` 는 **69.3%** 를 쓴다.
차이가 접기 pool 설정 때문인지 재측정 때문인지는 확인하지 못했다.
→ **보고서에는 69.3%를 쓴다.** 팀이 요약표·한계표·requirements 세 곳에서 반복해 쓴 값이다.

### E-7. 판정 단위 — 소호(6) → 호(4) (`4dc34a9`)

- 75건 중 **48건(64%)** 이 상위 3개 후보가 같은 호에 몰려 있었다 (`의사결정_기록.md:171`)
- 소호 1위 **34.7%** vs 호 3개 제시 **69.3%** (`:175-176`, `schemas.py:166`,
  `recommend_router.py:31-32`)
- 소호 이하는 통칙·주 규정 해석 구간이라 정확도가 **41%** 로 급락 (`:182`)
- 세번(10단위)에서 관세율이 결정되고 그건 전문가 검토 영역 (`:183`, `recommend_router.py:33`)

### E-8. 검색 실패와 분류 애매함의 구분 (`b50850b`)

- 증상 (`의사결정_기록.md:341-350`): `로스팅 전 원두` → 1801 코코아두(0.30) /
  3806 에스테르 검(0.25) / 0810 나무딸기(0.23). 화면은 차액 **47,300,000원** 과
  사전심사 권장을 냈다. 팀 판정 — `없는 분류 쟁점을 지어내는 것과 같다.`
- 대조 (`:354`): `커피 생두` → 0901 점수 **0.88**. 같은 물건인데 표현만 바꿔 무너졌다.
- 처리: 1위 점수 < **0.4** 또는 확신도 0 → `level = NONE`, 세액 비교 미출력.
  `hs_classifier.py:786` `MIN_CREDIBLE_SCORE = 0.4`, `:789-793` `is_search_failure()`
- 적용 결과 (`의사결정_기록.md:365-369`): 검색 실패로 제외 **9/75건(12.0%)**,
  그중 실은 정답 보유 2건(과잉 필터링 아님), 남은 66건 호 Top3 **68.0% → 74.2%**

### E-9. 세율 — readme의 하드코딩 22건은 죽은 항목이다

1층 readme:247 은 아직 `데모 품목 22건만 하드코딩` 이라고 적혀 있다. 커밋 `b50850b`
가 `DEMO_TARIFF_RATES` 22건을 제거하고 관세청 원본으로 완전 대체했다.

- 관세청 품목번호별 관세율표 **380,212행** → 고유 품목번호 11,326개, 소호 5,612개.
  폴백 **72/72건 → 0건** (`의사결정_기록.md:241-249`)
- `app/data/tariff_basic.csv` / `tariff_fta.csv` 각 5,613줄(헤더 포함) — 파일 실측
- WTO 양허가 기본세율보다 낮은 소호 **26.9%**(1,509개). 노트북 8% → 0% (`:253`)
- 소호 내부에서 세율이 갈리는 비율 **6.2%**(347개). 93.8%는 6단위로 충분 (`:254`)
- `U` 코드는 전 품목 11,326개가 예외 없이 0%라 조건부 세율로 판단하고
  **계산에 넣지 않았다. 정체는 미확인** (`:266-270`)
- 후보 3개의 세액이 완전히 같은 건 **39/72(54.2%)** — `hs_classifier.py:802-811`.
  이게 `정확도 69%여도 서비스가 성립하는` 근거로 코드 주석에 적혀 있다

### 확신도 산식 (`hs_classifier.py:552-560`)

```python
확신도 = score_1 × (1 − GAP_DISCOUNT × (score_2 / score_1) ** GAP_EXPONENT) × evidence
```
- 1위 점수를 그대로 쓰지 않고 **1·2위 격차**와 **맞은 개념 수**를 함께 본다
- 주석 원문: `점수가 높아도 2위가 비슷하면 그건 '확신'이 아니라 '애매함'이기 때문이다.`
- `"구리선"` 이 오답을 **확신도 1.0** 으로 자동 확정한 사례가 있었고, 세 번째 항(근거 2개
  이상)으로 막았다 (readme:202). 1층 사건이며 자동 확정 제거와는 별개다

(갱신 2026-08-11: 팀 저장소 커밋 `4dc34a9`·`b50850b` 를 반영. 기존 E절은 readme 커밋
`95932b6` 만 읽어 자동 확정·임계값 22건 표·의존성 0 세 항목이 팀 최종 코드와 어긋나
있었다. 1층/2층 구조로 나눠 옛 값을 지우지 않고 남겼고, E-2 자동 확정 제거,
E-3 75건 재측정과 테스트셋 편향, E-5 torch 의존성과 이미지 크기, E-6 하이브리드 검색,
E-7 호 단위 전환, E-8 검색 실패 감지, E-9 관세청 실세율을 새로 넣었다.
E-4는 MIN_CONCEPTS가 이번 커밋이 아니라 `072db33` 소속임을 확정한 것이다.)

---

## F. 인용할 코드 조각

### F-1. Kafka Consumer — DTO가 아니라 Map으로 받는 이유
`enrollment-service/src/main/java/com/lecture/enrollment/kafka/EnrollmentKafkaConsumer.java`
```java
@KafkaListener(topics = "${kafka.topic.payment-completed}",
               groupId = "${spring.kafka.consumer.group-id}")
public void handlePaymentCompleted(Map<String, Object> event) {
    Long userId   = ((Number) event.get("userId")).longValue();
    Long courseId = ((Number) event.get("courseId")).longValue();
    enrollmentService.activateEnrollment(userId, courseId);
}
```

### F-2. 서비스 이름으로 부르는 호출
`docker-compose.yml` — 어느 서비스에도 다른 서비스의 IP·포트가 없다
```yaml
- EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://eureka-server:8761/eureka/
```
`WebClientConfig.java:15-19` — `@LoadBalanced WebClient.Builder`
Gateway 라우팅 — `uri: lb://enrollment-service`

### F-3. 카테고리 enum과 그 경고 주석
`course-service/.../entity/Course.java:59-70`
```java
/**
 * 품목 분야 — HS 부호 상위 류(類) 기준으로 묶은 검토 서비스 카테고리.
 * 값을 바꾸면 recommend-service의 CourseCategory(Python), 프론트 카테고리 맵 3곳,
 * EnrollmentService.normalizeCategory() 가 함께 바뀌어야 한다.
 */
public enum Category { ELECTRONICS, CHEMICAL, TEXTILE, FOOD_AGRI, METAL, OTHER }
```

---

## G. 트러블슈팅 후보

| # | 증상 | 원인 | 해결 | 출처 |
|---|---|---|---|---|
| 1 | 8080에서 무토큰 호출이 401. course-service 권한 규칙이 동작한 줄 알았음 | Gateway `PUBLIC_PATHS` 에 `/api/courses/**` 가 없어 **경로 불문 먼저** 401로 막는다. 서비스 규칙은 실행조차 안 됨 | 8082 직결 401로 재검증해야 서비스 규칙의 실증이 됨 | QA 리포트 US-04 |
| 2 | 결제는 200인데 처리 건수만 조용히 안 오름 | `internal/{id}/enrollment-count` 호출이 막히면 catch로 **삼켜진다** | internal POST 경로를 전용 규칙으로 별도 개방 | QA 리포트 "경계면 위험" |
| 3 | 카테고리를 하나만 바꾸면 recommend 파싱 실패 + 프론트 필터가 **조용히 빈 목록** 반환 | 같은 값이 Java·Python·Vue·SQL 7개 지점에 흩어져 있음 | `check_category_sync.sh` 로 빌드 전 검사 | 팀 readme |
| 4 | 코드를 고쳐도 화면에 반영 안 됨 | **다른 디렉토리에서 띄운 스택**이 살아 있음 | `health_check.sh` 0번 항목이 스택 출처를 먼저 경고 | 팀 readme |
| 5 | `docker compose down -v` 후 등록 데이터 전부 소실 | 볼륨 삭제. 계정만 auth-server가 재시드, 나머지는 복구 불가 | `-v` 없이 `down` | 팀 readme 경고 |
| 6 | Kafka 이벤트를 DTO로 받으면 역직렬화 실패 | payment-service가 JsonSerializer + **type header 없이** 발행 | Consumer에서 `Map<String,Object>` 로 수신 | Consumer 주석 |
| 7 | `"구리선"` 이 오답을 확신도 **1.0** 으로 자동 확정 | 1위 점수만 보면 근거 낱말이 하나뿐이어도 만점 | 확신도 산식에 "맞은 개념 수" 항 추가 | 팀 readme |
| 8 | Swagger가 Gateway에 안 모임 | Gateway는 API 라우팅만 집계 | 서비스 포트로 직접 접속 (`:8082/swagger-ui/index.html`) | 팀 readme |
| 9 | `POST /users/login` 이 404 | 로그인이 OAuth2 2단계(`/oauth2/authorize` → `/oauth2/token`)라 그런 엔드포인트가 없음 | OAuth2 흐름으로 호출 | 팀 readme |
| 10 | (잠재) 권한을 켜는 순간 전부 401 | user·enrollment·payment의 `issuer-uri` 가 `http://auth-server:9000` 인데 auth-server는 `http://localhost:8080` 으로 발급 | 현재 permitAll이라 무증상. **미해결로 문서화됨** | 팀 readme "알려진 한계" |

---

## H. 미확인

- (미확인) 인프라 이미지 `infra-images.tar` 는 저장소에 없어 직접 기동 검증은 못 함
- (미확인) 프론트 결제 버튼 클릭 → 배너 표시 화면은 미촬영 (QA 리포트 미검증 4건에 포함)
- (미확인) 관세사 추천 카드 3장이 실제로 그려진 화면은 아직 미확인 (QA 리포트 미검증 #3)
