package com.example.menu.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Swagger(OpenAPI) 문서의 제목과 설명을 정의합니다.
 *
 * springdoc이 Controller를 읽어 엔드포인트 목록을 자동으로 만들지만,
 * 문서 상단의 제목·설명은 이렇게 직접 지정해야 합니다.
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI menuOpenAPI() {
        return new OpenAPI().info(new Info()
                .title("오늘 뭐 먹지? — 메뉴 추천 API")
                .version("v1.0.0")
                .description("""
                        Spring Boot 실습용 메뉴 추천 REST API입니다.

                        - 실습과제 ①~④ (날씨 · 기분 · 가격대 · 함께 먹는 사람)
                        - ②는 JSON(MenuResponse), 나머지는 문자열로 응답합니다.
                        - 가격대별 추천은 min > max인 경우 400 Bad Request를 반환합니다.
                        """));
    }
}
