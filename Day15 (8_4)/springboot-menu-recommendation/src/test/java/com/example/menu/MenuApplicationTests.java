package com.example.menu;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * MockMvc로 실습과제 API를 자동 검증합니다.
 *
 * 서버를 직접 띄우지 않고 DispatcherServlet에 가짜 요청을 보내
 * 상태 코드·응답 본문·JSON 필드를 확인합니다.
 */
@SpringBootTest
@AutoConfigureMockMvc
class MenuApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("Spring Container가 정상적으로 기동된다")
    void contextLoads() {
    }

    @Test
    @DisplayName("과제① 날씨별 추천 - 날씨에 따라 다른 메뉴를 문자열로 반환한다")
    void weatherApiReturnsDifferentMenus() throws Exception {
        mockMvc.perform(get("/api/menu/weather/rainy"))
                .andExpect(status().isOk())
                .andExpect(content().string("rainy 날씨에 어울리는 메뉴는 칼국수입니다."));

        mockMvc.perform(get("/api/menu/weather/hot"))
                .andExpect(status().isOk())
                .andExpect(content().string("hot 날씨에 어울리는 메뉴는 냉면입니다."));
    }

    @Test
    @DisplayName("과제① 정해지지 않은 날씨는 안내 문구를 반환한다")
    void weatherApiGuidesOnUnknownValue() throws Exception {
        mockMvc.perform(get("/api/menu/weather/snowy"))
                .andExpect(status().isOk())
                .andExpect(content().string(
                        containsString("추천 가능한 메뉴가 없습니다")));
    }

    @Test
    @DisplayName("과제② 기분별 추천 - MenuResponse가 JSON 세 필드로 직렬화된다")
    void moodApiReturnsJson() throws Exception {
        mockMvc.perform(get("/api/menu/mood/happy"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.category").value("happy"))
                .andExpect(jsonPath("$.menu").value("치킨"))
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    @DisplayName("과제③ 가격대별 추천 - max 구간에 따라 메뉴가 나뉜다")
    void priceApiSplitsByMax() throws Exception {
        mockMvc.perform(get("/api/menu/price/search").param("min", "1000").param("max", "5000"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("김밥")));

        mockMvc.perform(get("/api/menu/price/search").param("min", "5000").param("max", "10000"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("돈가스")));

        mockMvc.perform(get("/api/menu/price/search").param("min", "15000").param("max", "30000"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("소고기 구이")));
    }

    /**
     * MockMvc는 서블릿 컨테이너의 /error 포워딩을 거치지 않으므로
     * 400 응답 본문이 비어 있다. 따라서 상태 코드와 함께
     * Controller가 실제로 던진 예외와 그 사유를 확인한다.
     * (본문에 message가 실리는지는 실행 중인 서버에서 curl로 확인)
     */
    @Test
    @DisplayName("과제③ min > max 이면 400 Bad Request를 반환한다")
    void priceApiRejectsInvalidRange() throws Exception {
        mockMvc.perform(get("/api/menu/price/search").param("min", "20000").param("max", "5000"))
                .andExpect(status().isBadRequest())
                .andExpect(result -> {
                    Exception thrown = result.getResolvedException();
                    assertThat(thrown).isInstanceOf(ResponseStatusException.class);
                    assertThat(((ResponseStatusException) thrown).getReason())
                            .contains("min(20000)", "max(5000)", "클 수 없습니다");
                });
    }

    @Test
    @DisplayName("과제③ 숫자가 아닌 값을 주면 400 Bad Request를 반환한다")
    void priceApiRejectsNonNumericInput() throws Exception {
        mockMvc.perform(get("/api/menu/price/search").param("min", "abc").param("max", "5000"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("과제④ 나만의 추천 - 같이 먹는 사람에 따라 메뉴가 달라진다")
    void companionApiReturnsPersonalizedMenu() throws Exception {
        mockMvc.perform(get("/api/menu/my/solo"))
                .andExpect(status().isOk())
                .andExpect(content().string("혼자 먹기 좋은 라면 어떠세요?"));

        mockMvc.perform(get("/api/menu/my/family"))
                .andExpect(status().isOk())
                .andExpect(content().string("가족과 함께라면 불고기 어떠세요?"));
    }

    @Test
    @DisplayName("기존 API가 그대로 동작한다 (회귀 확인)")
    void existingApisStillWork() throws Exception {
        mockMvc.perform(get("/api/menu"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("김치찌개")));

        mockMvc.perform(get("/api/menu/json/korean"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.menu").value("불고기"));
    }

    @Test
    @DisplayName("Swagger 문서(OpenAPI)가 실습과제 API를 모두 노출한다")
    void openApiDocumentationExposesAssignmentApis() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/menu/weather/{weather}']").exists())
                .andExpect(jsonPath("$.paths['/api/menu/mood/{mood}']").exists())
                .andExpect(jsonPath("$.paths['/api/menu/price/search']").exists())
                .andExpect(jsonPath("$.paths['/api/menu/my/{companion}']").exists())
                .andExpect(jsonPath("$.info.title").value("오늘 뭐 먹지? — 메뉴 추천 API"));
    }
}
