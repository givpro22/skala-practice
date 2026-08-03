# Day 8 종합실습-4 · ecommerce 매출 분석 및 성능 튜닝

AI 서비스를 위한 SW 기초 Full-stack Engineering — 스마트 데이터 이해 및 활용 · 광주캠퍼스 4반 박영서

## 제출물
- **[광주캠퍼스_4반_박영서_day8종합실습.pdf](광주캠퍼스_4반_박영서_day8종합실습.pdf)** — 최종 리포트 (튜닝 전/후 실행계획·결과 캡처 포함)

## 제출물
1. **Q1~Q11 튜닝 전/후** — 각 문항별 baseline 실행계획(EXPLAIN ANALYZE) → 병목 분석 → 튜닝(인덱스/재작성) → 튜닝 후 실행계획·결과 비교
2. **3가지 조인 비교** — Nested Loop / Hash / Merge Join 강제 실행계획 및 특성 비교
3. **Materialized View** — mv_daily_gmv 생성·갱신 스크립트 및 리포트 가속(약 860배) 검증

## 폴더 구성
```
day8/
├─ 종합실습4_ecom_schema_postgres_테이블생성.sql   # 스키마(교재 제공)
├─ 종합실습4_ecom_seed_postgres_데이터입력.sql      # 시드(교재 제공)
├─ sql/
│  ├─ 00_env.sql                 # 환경/데이터 규모 확인
│  ├─ 01_tuning_indexes.sql      # 튜닝용 인덱스 모음(부분·복합·커버링)
│  ├─ quiz/q01.sql ~ q11.sql     # 문항별 튜닝 전/후 쿼리(주석 포함)
│  ├─ 12_join_compare.sql        # 조인 3종 비교
│  └─ 13_materialized_view.sql   # MV 생성·갱신·비교
├─ outputs/run_log.txt           # 환경·조인·MV 실행 로그
└─ report/                       # 리포트 HTML + 캡처 41장
```

## 실행 방법
```bash
# 1) 스키마·데이터 적재 (확장 생성 위해 슈퍼유저 권장)
psql -d skala_db -f 종합실습4_ecom_schema_postgres_테이블생성.sql
psql -d skala_db -f 종합실습4_ecom_seed_postgres_데이터입력.sql

# 2) 튜닝 인덱스 생성
psql -d skala_db -f sql/01_tuning_indexes.sql

# 3) 문항 실행 (예: Q1)
PGOPTIONS='-c search_path=ecom,public' psql -d skala_db -f sql/quiz/q01.sql
```

## 실행 환경
- PostgreSQL 17.10 · DB `skala_db` · 스키마 `ecom`
- 데이터: orders 6,770 · order_items 18,393 · customers 3,000 · products 600 · reviews 2,064

## 핵심 결과 요약
| 기법 | 대표 문항 | 계획 변화 |
|------|-----------|-----------|
| 부분 인덱스 | Q1·Q7·Q10 | Seq Scan → (Bitmap) Index Scan |
| 복합 부분 인덱스 | Q6 | Index Scan → Index Only Scan |
| 커버링 인덱스 | Q8 | Seq Scan → Index Only Scan (Heap Fetches 0) |
| 쿼리 재작성 | Q2·Q5·Q9·Q11 | count(DISTINCT) Sort 제거 → HashAggregate |
| 옵티마이저 분석 | Q3·Q4 | 저선택도/전량집계 → Seq Scan 유지가 최적(크로스오버) |
| Materialized View | 일자별 GMV | JOIN+SUM(19ms) → Index Scan(0.02ms, 약 860배) |
