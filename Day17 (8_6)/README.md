# Day 17 · 주식 거래 분석 API — JPA · MyBatis · AOP

- **일자**: 2026-08-06 (목)
- **과정**: SKALA — Java · SpringBoot · Rest API 구현 (08.03~08.07, Day 14~18)
- **작성자**: 광주캠퍼스 4반 · G122 박영서

## 진행 내용

배포받은 `StockTrading2`는 실습을 위해 상당 부분이 제거된 상태였습니다
(분석 클래스는 주석만 남아 있었음). 필수 API를 복원하고 분석·통계 기능과
Actuator · AOP를 적용했습니다.

### 필수 API 8종

| 기능 | 엔드포인트 |
| --- | --- |
| User 전체 조회 · 삭제 | `GET /api/users` · `DELETE /api/users/{id}` |
| Stock 수정 · 삭제 | `PUT`/`DELETE /api/stocks/{id}` |
| Stock 코드로 조회 | `GET /api/stocks/code/{code}` |
| Transaction 상세 조회 | `GET /api/transactions/{id}` (읽기 전용) |
| Transaction 매매 실행 | `POST /api/transactions/trade` |
| Portfolio 특정 주식 | `GET /api/portfolios/user/{userId}/stock/{stockId}` |

### 분석 API 8종 (5개 이상 요구)

| 번호 | 기능 | 구현 |
| --- | --- | --- |
| ① | 포트폴리오 평가 손익 | JPA |
| ② | 거래 내역 상세 | JPA |
| ③ | 특정 주식 거래 내역 | JPA |
| ④ | 총 자산 조회 | **MyBatis** |
| ⑤ | 총 수익률 조회 | **MyBatis** |
| ⑥ | 거래 통계 조회 | **MyBatis** |
| ⑦ | 일별 거래 내역 | **MyBatis** |
| ⑧ | 거래 감사 로그 (AOP 결과 확인) | JPA |

### 기능 추가

- **Actuator** — `health`(하위 구성요소 포함) · `info` · `metrics` 등 7종 노출
- **AOP** — ① 서비스 실행 시간 측정 ② 거래 감사 로그 기록(별도 트랜잭션)

### 구현하며 신경 쓴 것

- **JPA와 MyBatis의 분담** — 엔티티 조작은 JPA, `GROUP BY`·`CASE WHEN` 집계는 MyBatis.
  같은 데이터라도 "무엇을 묻느냐"에 따라 도구를 나눴습니다.
- **매매는 한 트랜잭션** — 잔액·포트폴리오·거래 내역 세 가지가 함께 바뀌므로
  중간에 실패하면 모두 롤백되어야 합니다.
- **감사 로그는 별도 트랜잭션** — 실패한 거래도 "시도했다"는 사실은 남아야 하므로
  `REQUIRES_NEW`로 분리했습니다. 거래 트랜잭션에 얹으면 롤백과 함께 사라집니다.
- **삭제 시 참조 무결성** — 참조가 남아 있으면 500 대신 **409**와 사유를 반환합니다.

## 폴더 구성

```
Day17 (8_6)/
└─ StockTrading2/         주식 거래 분석 API (Spring Boot 3.2.0 · JPA + MyBatis · H2)
   ├─ docs/               제출용 PDF 보고서와 실행 화면 캡처
   └─ src/
```

> 배포 원본 `StockTrading2.zip`은 압축을 푼 소스를 그대로 추적하므로 `.gitignore`로 제외했습니다.

## 제출물

- [광주_4반_박영서_day4주식거래분석API.pdf](<StockTrading2/docs/광주_4반_박영서_day4주식거래분석API.pdf>) — 31페이지
- 실행 화면 캡처 19장 (Swagger 16장 · 터미널 3장)

## 이전 실습

| Day | 내용 |
| --- | --- |
| [Day 14](<../Day14 (8_3)>) | Java 기초 · SpringBoot 프로젝트 구성 · REST API 설계 |
| [Day 15](<../Day15 (8_4)>) | Configuration/Profile · 메뉴 추천 REST API (Swagger · 자동 테스트 · Docker) |
| [Day 16](<../Day16 (8_5)>) | 주식 거래 REST API — JPA · Actuator · Validation · Docker |
