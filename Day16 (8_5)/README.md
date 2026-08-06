# Day 16 · 주식 거래 REST API 기능 확장

- **일자**: 2026-08-05 (수)
- **과정**: SKALA — Java · SpringBoot · Rest API 구현 (08.03~08.07, Day 14~18)
- **작성자**: 광주캠퍼스 4반 · G122 박영서

## 진행 내용

배포받은 `StockTrading` 프로젝트(Spring Boot + JPA, 생성·조회만 구현된 상태)에
수정·삭제 API를 추가하고 운영 관점의 기능을 붙였습니다.

| 과제 | 내용 | 결과 |
| --- | --- | --- |
| 1 | `updateStock` · `deleteStock` — `PUT`/`DELETE /api/stocks/{id}` | 200 / 204 |
| 2 | `updateUser` · `deleteUser` — `PUT`/`DELETE /api/users/{id}` | 200 / 204 |
| 3 | `getStockByCode` — `GET /api/stocks/code/{code}` | 200 |
| 4 | Actuator 적용 — `health` · `info` · `metrics` 등 7종 노출 | 완료 |
| 5 | Validation 적용 — 전역 예외 처리, 상태 코드 매핑 | 완료 |
| 6 | Docker — 멀티 스테이지 빌드, 비root 실행, HEALTHCHECK | healthy |

### 구현하며 신경 쓴 것

- **삭제 시 참조 무결성** — `portfolios`·`transactions`가 `user_id`/`stock_id`를 NOT NULL
  외래키로 참조하므로, 참조가 남은 채 삭제하면 500이 납니다. 삭제 전에 확인해 **409**로 거절합니다.
- **수정 시 중복 검사** — 값이 바뀐 경우에만 검사해 자기가 쓰던 코드/사용자명과 충돌하지 않게 했습니다.
- **검증 범위** — 경로 변수 제약은 클래스에 `@Validated`가 있어야 동작합니다.
  주식·사용자뿐 아니라 포트폴리오·거래 컨트롤러까지 네 곳 모두 적용했습니다.

## 폴더 구성

```
Day16 (8_5)/
└─ StockTrading/          주식 거래 REST API (Spring Boot 3.2.0 · JPA · H2)
   ├─ docs/               제출용 PDF 보고서와 실행 화면 캡처
   ├─ Dockerfile
   └─ src/
```

> 배포 원본 `StockTrading.zip`은 압축을 푼 소스를 그대로 추적하므로 `.gitignore`로 제외했습니다.

## 제출물

- [광주_4반_박영서_day3주식거래API.pdf](<StockTrading/docs/광주_4반_박영서_day3주식거래API.pdf>) — 21페이지
- 실행 화면 캡처 14장 (Swagger 10장 · 터미널 4장)

## 이전 실습

| Day | 내용 |
| --- | --- |
| [Day 14](<../Day14 (8_3)>) | Java 기초 · SpringBoot 프로젝트 구성 · REST API 설계 |
| [Day 15](<../Day15 (8_4)>) | Configuration/Profile 샘플 · 메뉴 추천 REST API (Swagger · 테스트 · Docker) |
