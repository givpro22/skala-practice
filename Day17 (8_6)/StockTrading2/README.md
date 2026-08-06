# 주식 거래 분석 API (StockTrading2)

Spring Boot + JPA + MyBatis로 만든 주식 거래·분석 실습 프로젝트입니다.
매매를 실행하고, 보유 현황과 자산·수익률·거래 통계를 조회합니다.

- **환경**: Java 21 · Spring Boot 3.2.0 · Spring Data JPA · MyBatis 3.0.3 · H2 · Gradle 8.5
- **부가 기능**: Swagger UI · Actuator · AOP

## 실행 방법

```bash
./gradlew bootRun
```

| 주소 | 용도 |
| --- | --- |
| `http://localhost:8080/swagger-ui.html` | API 문서 · 직접 실행 |
| `http://localhost:8080/actuator` | 애플리케이션 상태 |
| `http://localhost:8080/h2-console` | H2 콘솔 (JDBC URL `jdbc:h2:mem:stockdb`) |

> H2 인메모리라 재시작하면 데이터가 초기화되고 `data.sql`의 기본 데이터가 다시 적재됩니다.

## API 목록

### 주식 · 사용자

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| `POST` | `/api/stocks` | 주식 등록 |
| `GET` | `/api/stocks` · `/api/stocks/{id}` | 전체 · ID 조회 |
| `GET` | `/api/stocks/code/{code}` | **종목 코드로 조회** (예: `005930`) |
| `PUT` · `DELETE` | `/api/stocks/{id}` | **수정 · 삭제** |
| `POST` | `/api/users` | 사용자 등록 |
| `GET` | `/api/users` · `/api/users/{id}` | **전체** · ID 조회 |
| `DELETE` | `/api/users/{id}` | **삭제** |

### 거래 · 포트폴리오

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| `POST` | `/api/transactions/trade` | **매수·매도 실행** (`type`: `BUY` / `SELL`) |
| `GET` | `/api/transactions/{id}` | **거래 상세 조회** |
| `GET` | `/api/transactions/user/{userId}` | 사용자 거래 내역 |
| `GET` | `/api/transactions/user/{userId}/stock/{stockId}` | **특정 종목 거래 내역** |
| `GET` | `/api/portfolios/user/{userId}` | 사용자 포트폴리오 |
| `GET` | `/api/portfolios/user/{userId}/stock/{stockId}` | **특정 종목 보유 현황** |

### 분석

| 메서드 | 경로 | 설명 | 구현 |
| --- | --- | --- | --- |
| `GET` | `/api/analysis/portfolio/{userId}` | 포트폴리오 평가 손익 | JPA |
| `GET` | `/api/analysis/transactions/{userId}` | 거래 내역 상세 | JPA |
| `GET` | `/api/analysis/transactions/{userId}/stock/{stockId}` | 특정 주식 거래 내역 | JPA |
| `GET` | `/api/analysis/assets/{userId}` | 총 자산 (현금 + 평가액) | MyBatis |
| `GET` | `/api/analysis/return-rate/{userId}` | 총 수익률 | MyBatis |
| `GET` | `/api/analysis/statistics/{userId}` | 종목별 거래 통계 | MyBatis |
| `GET` | `/api/analysis/daily/{userId}` | 일별 거래 집계 | MyBatis |
| `GET` | `/api/analysis/audit/{userId}` | 거래 감사 로그 (AOP 결과) | JPA |

**굵게 표시한 것**이 이번 실습에서 복원·추가한 API입니다.

## 설계 메모

### JPA와 MyBatis를 나눈 기준

| 도구 | 쓰는 곳 | 이유 |
| --- | --- | --- |
| JPA | 엔티티 단위 조회·CRUD | 객체로 다루는 것이 자연스럽고 연관관계 탐색이 쉽다 |
| MyBatis | `GROUP BY`·`CASE WHEN` 집계 | SQL을 직접 쓰는 편이 읽기 쉽고 의도가 분명하다 |

집계 SQL은 `src/main/resources/mapper/StockMapper.xml`에 있습니다.
`map-underscore-to-camel-case: true` 설정으로 `stock_code` → `stockCode` 자동 매핑됩니다.

### 매매 트랜잭션

매매 한 번에 **잔액 · 포트폴리오 · 거래 내역** 세 가지가 함께 바뀝니다.
중간에 실패하면 모두 되돌아가야 하므로 `@Transactional`로 묶었습니다.

평균 매수가는 매수 시에만 다시 계산합니다.

```
새 평균가 = (기존 평가액 + 이번 매수액) / (기존 수량 + 이번 수량)
```

매도는 이미 산 것의 일부를 넘기는 일이라 "얼마에 샀는지"가 변하지 않으므로
평균가를 건드리지 않고 수량만 줄입니다. 0이 되면 보유 목록에서 제거합니다.

### AOP

| 클래스 | 역할 |
| --- | --- |
| `ExecutionTimeAspect` | 서비스 계층 실행 시간 측정 (100ms 이상은 `WARN`) |
| `TradeAuditAspect` | 매매 성공·실패 시 감사 로그 기록 |

감사 로그에는 메시지뿐 아니라 **그 시점의 총 자산·수익률 스냅샷**도 함께 저장합니다
(MyBatis `selectTradeSnapshot` 한 번). 로그만 보고도 "이 거래 직후 자산이 얼마였는지"를
알 수 있어야 감사 기록으로서 쓸모가 있기 때문입니다.

저장은 `TradeAuditRecorder`가 **`REQUIRES_NEW`로 별도 트랜잭션**에서 처리합니다.
실패한 거래도 "시도했다"는 사실이 남아야 하는데, 거래 트랜잭션에 얹으면
롤백될 때 로그까지 사라지기 때문입니다.

`TradeAuditAspect`에는 `@Order(0)`을 붙여 트랜잭션 어드바이저보다 바깥에서 돌게 했습니다.

## 오류 응답

모든 오류는 `GlobalExceptionHandler`를 거쳐 같은 형식으로 반환됩니다.

```json
{
  "timestamp": "2026-08-06T17:52:07.801583",
  "status": 400,
  "error": "Bad Request",
  "message": "입력값이 올바르지 않습니다",
  "path": "/api/analysis/assets/0",
  "fieldErrors": { "userId": "사용자 ID는 1 이상이어야 합니다" }
}
```

| 상황 | 상태 코드 |
| --- | --- |
| 입력값 검증 실패 · 타입 불일치 · 깨진 JSON | `400` |
| 잔액 부족 · 보유 수량 부족 | `400` |
| 자원 없음 | `404` |
| 없는 경로 / 지원하지 않는 메서드 | `404` / `405` |
| 중복된 값 · 참조 중이라 삭제 불가 | `409` |

`portfolios`·`transactions`가 `user_id`/`stock_id`를 NOT NULL 외래키로 참조하므로,
참조가 남아 있으면 삭제 대신 `409`와 사유를 반환합니다.

## 프로젝트 구조

```
src/main/java/com/skala/stock/
├─ aop/            ExecutionTimeAspect · TradeAuditAspect
├─ controller/     요청 매핑 · 입력 검증 (@Validated)
├─ service/        비즈니스 로직 · 트랜잭션
├─ repository/     Spring Data JPA
├─ mapper/         MyBatis 집계 쿼리
├─ entity/         User · Stock · Portfolio · Transaction · TradeAuditLog
├─ dto/            요청/응답 DTO · ErrorResponse
└─ exception/      GlobalExceptionHandler · 예외 타입 4종
```

## 알려진 제약

- `UserDto`가 응답에 비밀번호를 그대로 포함합니다. 요청용·응답용 DTO 분리가 필요합니다.
- 자동 테스트가 없습니다. 특히 평균 매수가 계산과 트랜잭션 롤백은 테스트 가치가 큽니다.
- 금액을 `Long`으로 다뤄 소수점 단위 가격에는 맞지 않습니다. `BigDecimal`이 안전합니다.
- 동시에 같은 종목을 매매하면 포트폴리오 갱신에 경합이 생길 수 있습니다.

## 제출 보고서

[docs/광주_4반_박영서_day4주식거래분석API.pdf](<docs/광주_4반_박영서_day4주식거래분석API.pdf>) — 구현 내용과 실행 화면 31페이지
