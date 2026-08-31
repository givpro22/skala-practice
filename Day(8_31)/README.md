# 8/31 · Spring AI 개발환경 구성

- **일자**: 2026-08-31 (일)
- **과정**: SKALA — SpringAI 이해 및 활용 (2일 과정)
- **작성자**: 광주캠퍼스 4반 · 박영서
- **진행 범위**: 교재 32쪽까지 (1장 AI·LLM 기초, 2장 Spring AI 아키텍처, 3장 개발환경 설정)

## 구성 결과

| 항목 | 값 | 확인 |
| --- | --- | --- |
| JDK | Temurin 21.0.11 LTS | `java -version` |
| Ollama | 0.33.0 | `curl localhost:11434/api/version` |
| 로컬 모델 | qwen3.5:2b (2.7GB) | `/api/generate` 응답 확인 |
| 프로젝트 | `springai` (Gradle Groovy, Java 21) | `./gradlew build` 성공 |
| Spring Boot | 4.1.0 | |
| Spring AI | BOM 2.0.0 · OpenAI 스타터 | |
| Swagger UI | springdoc 2.8.6 | `/swagger-ui/index.html` 200 |

## 실행

```bash
ollama serve &                    # 이미 떠 있으면 생략
cd springai
./gradlew bootRun
```

- Swagger UI: http://localhost:8080/swagger-ui/index.html
- API 문서: http://localhost:8080/v3/api-docs

## 교재와 다르게 둔 부분

- 30쪽 표는 Gradle-Kotlin · Spring Boot 3.5.x 로 되어 있으나, 31쪽 build.gradle 이
  Groovy 문법에 Boot 4.1.0 · Spring AI 2.0.0 이므로 31쪽을 따랐다. 현재
  start.spring.io 도 3.5.x 를 더 이상 제공하지 않는다.
- 의존성에 Ollama 스타터가 없어 31쪽 그대로 OpenAI 스타터만 넣었다. Ollama 는
  아직 curl 로만 확인한다.
- `application.yml` 에 `spring.ai.openai.api-key` 한 줄을 미리 넣었다(34쪽 내용).
  이 속성이 아예 없으면 OpenAI 자동 구성이 자격 증명을 찾다 실패해서
  `./gradlew build` 의 컨텍스트 로딩 테스트가 깨진다. 값은 환경변수 참조만 남겼다.

## 키 보관

OpenAI 키는 저장소 밖 `~/.config/skala/openai.env` 에 두고 권한을 600 으로 막았다.
`application.yml` 에는 환경변수 참조만 있고 값은 없다.

```bash
source ~/.config/skala/openai.env
./gradlew bootRun
```

매번 치기 싫으면 `~/.zshrc` 끝에 아래 한 줄을 넣는다.

```bash
[ -f "$HOME/.config/skala/openai.env" ] && source "$HOME/.config/skala/openai.env"
```
