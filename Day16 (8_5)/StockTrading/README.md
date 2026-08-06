# 주식 거래 REST API (StockTrading)

Spring Boot + JPA로 만든 주식 거래 실습 프로젝트입니다.
사용자가 예수금으로 주식을 매수·매도하고, 보유 현황(포트폴리오)과 거래 내역을 조회합니다.

- **환경**: Java 21 · Spring Boot 3.2.0 · Spring Data JPA · H2 (인메모리) · Gradle 8.5
- **문서**: Swagger UI · Actuator

## 실행 방법

```bash
./gradlew bootRun
```

Docker로 실행하려면:

```bash
docker build -t stock-trading:latest .
docker run -d --name stock-app -p 8080:8080 stock-trading:latest
```

| 주소 | 용도 |
| --- | --- |
| `http://localhost:8080/swagger-ui.html` | API 문서 · 직접 실행 |
| `http://localhost:8080/actuator` | 애플리케이션 상태 |
| `http://localhost:8080/h2-console` | H2 콘솔 (JDBC URL `jdbc:h2:mem:stockdb`) |

> H2 인메모리라 앱을 재시작하면 데이터가 초기화되고, `data.sql`의 기본 데이터가 다시 적재됩니다.

## API 목록

### 주식

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| `POST` | `/api/stocks` | 주식 등록 |
| `GET` | `/api/stocks` | 전체 조회 |
| `GET` | `/api/stocks/{id}` | ID로 조회 |
| `GET` | `/api/stocks/code/{code}` | **종목 코드로 조회** (예: `005930`) |
| `PUT` | `/api/stocks/{id}` | **수정** |
| `DELETE` | `/api/stocks/{id}` | **삭제** |

### 사용자

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| `POST` | `/api/users` | 사용자 등록 |
| `GET` | `/api/users` | 전체 조회 |
| `GET` | `/api/users/{id}` | ID로 조회 |
| `PUT` | `/api/users/{id}` | **수정** |
| `DELETE` | `/api/users/{id}` | **삭제** |

### 거래 · 포트폴리오

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| `POST` | `/api/transactions/trade` | 매수·매도 실행 (`type`: `BUY` / `SELL`) |
| `GET` | `/api/transactions/{id}` | 거래 상세 |
| `GET` | `/api/transactions/user/{userId}` | 사용자 거래 내역 |
| `GET` | `/api/portfolios/user/{userId}` | 사용자 포트폴리오 |
| `GET` | `/api/portfolios/user/{userId}/stock/{stockId}` | 특정 종목 보유 현황 |

**굵게 표시한 6개**가 이번 실습에서 추가한 API입니다.

## 오류 응답

모든 오류는 `GlobalExceptionHandler`를 거쳐 같은 형식으로 반환됩니다.

```json
{
  "timestamp": "2026-08-05T10:15:00.522128292",
  "status": 400,
  "error": "Bad Request",
  "message": "입력값이 올바르지 않습니다",
  "path": "/api/stocks/0",
  "fieldErrors": { "id": "ID는 1 이상이어야 합니다" }
}
```

| 상황 | 상태 코드 |
| --- | --- |
| 입력값 검증 실패 · 타입 불일치 · 깨진 JSON | `400` |
| 잔액 부족 · 보유 수량 부족 | `400` |
| 자원 없음 | `404` |
| 없는 경로 / 지원하지 않는 메서드 | `404` / `405` |
| 중복된 값 · 참조 중이라 삭제 불가 | `409` |

`fieldErrors`는 입력값 검증에 실패했을 때만 포함됩니다.

### 삭제가 거절되는 경우

`portfolios`·`transactions`가 `user_id`/`stock_id`를 **NOT NULL 외래키**로 참조합니다.
참조가 남아 있으면 삭제 대신 `409`와 사유를 반환합니다.

```bash
curl -X DELETE localhost:8080/api/stocks/1
# 409 { "message": "보유 중인 포트폴리오가 있어 삭제할 수 없습니다: 005930" }
```

거래 내역은 "언제 무엇을 얼마에 샀다"는 기록이므로, 사용자를 지운다고 함께 삭제하지 않습니다.

## 프로젝트 구조

```
src/main/java/com/skala/stock/
├─ controller/     요청 매핑 · 입력 검증 (@Validated)
├─ service/        비즈니스 로직 · 트랜잭션
├─ repository/     Spring Data JPA
├─ entity/         User · Stock · Portfolio · Transaction
├─ dto/            요청/응답 DTO · ErrorResponse
└─ exception/      GlobalExceptionHandler · 예외 타입 4종
```

## Actuator

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, env, beans, mappings
```

- `/actuator/health` — DB·디스크 등 하위 구성요소 상태까지 표시
- `/actuator/mappings` — 등록된 URL 매핑 확인 (엔드포인트 추가 후 검증에 유용)
- Docker `HEALTHCHECK`도 `/actuator/health`를 사용합니다

## 알려진 제약

- `UserDto`가 응답에 비밀번호를 그대로 포함합니다. 요청용·응답용 DTO 분리가 필요합니다.
- 수정 API가 전체 필드를 받으므로 일부만 바꾸려 해도 모든 값을 보내야 합니다.
- 자동 테스트가 없습니다. 검증은 Swagger와 `curl`로 수동 확인했습니다.

## 제출 보고서

[docs/광주_4반_박영서_day3주식거래API.pdf](<docs/광주_4반_박영서_day3주식거래API.pdf>) — 구현 내용과 실행 화면 21페이지
