# ── 1단계: 빌드 ──────────────────────────────────────────────
# jar를 만들 때는 컴파일러가 필요하므로 JDK 이미지를 쓴다.
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build

# 의존성 파일을 소스보다 먼저 복사한다.
# 소스만 고쳤을 때 이 아래 레이어 캐시가 재사용되어 재빌드가 빨라진다.
COPY gradlew ./
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

COPY src src
RUN ./gradlew bootJar --no-daemon -x test

# ── 2단계: 실행 ──────────────────────────────────────────────
# 실행에는 JRE면 충분하므로 최종 이미지에 컴파일러를 넣지 않는다.
FROM eclipse-temurin:21-jre
WORKDIR /app

# root로 실행하지 않는다. 컨테이너가 뚫려도 권한을 제한하기 위함.
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

COPY --from=builder /build/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
