package com.example.menu.controller;

import com.example.menu.dto.MenuResponse;
import com.example.menu.service.MenuService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * 브라우저의 HTTP 요청을 받아 메뉴 추천 결과를 반환한다.
 */
@RestController
@RequestMapping("/api")
@Tag(name = "메뉴 추천", description = "상황에 맞는 메뉴를 추천합니다.")
public class MenuController {

    private final MenuService menuService;

    /**
     * Spring Container가 MenuService Bean을 생성자에 주입합니다.
     */
    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    @Operation(summary = "인사", description = "이름을 받아 인사말을 돌려줍니다.")
    @GetMapping("/hello/{name}")
    public String hello(
            @Parameter(description = "이름", example = "홍길동")
            @PathVariable("name") String name) {
        return name + "님, 오늘도 맛있는 하루 보내세요!";
    }

    @Operation(summary = "기본 추천", description = "고정된 기본 메뉴를 추천합니다.")
    @GetMapping("/menu")
    public String menu() {
        return "오늘의 추천 메뉴는 " + menuService.recommend() + "입니다.";
    }

    @Operation(summary = "랜덤 추천", description = "메뉴 목록에서 무작위로 하나를 고릅니다.")
    @GetMapping("/menu/random")
    public String randomMenu() {
        return "오늘은 " + menuService.randomMenu() + " 어떠세요?";
    }

    @Operation(summary = "카테고리별 추천", description = "korean / chinese / japanese / snack")
    @GetMapping("/menu/{category}")
    public String menuByCategory(
            @Parameter(description = "카테고리", example = "korean")
            @PathVariable("category") String category) {
        String menu = menuService.recommendByCategory(category);
        return category + " 추천 메뉴는 " + menu + "입니다.";
    }

    @Operation(summary = "카테고리별 추천 (JSON)", description = "위와 같은 로직을 JSON으로 응답합니다.")
    @GetMapping("/menu/json/{category}")
    public MenuResponse menuJson(
            @Parameter(description = "카테고리", example = "korean")
            @PathVariable("category") String category) {
        String menu = menuService.recommendByCategory(category);

        return new MenuResponse(
                category,
                menu,
                "오늘은 " + menu + " 어떠세요?"
        );
    }

    /**
     * 실습과제① 날씨별 추천 — 문자열로 응답한다.
     */
    @Operation(summary = "[과제①] 날씨별 추천",
            description = "sunny / rainy / hot / cold 네 가지 날씨에 따라 다른 메뉴를 추천합니다. "
                    + "정해진 값이 아니면 안내 문구를 반환합니다.")
    @GetMapping("/menu/weather/{weather}")
    public String menuByWeather(
            @Parameter(description = "날씨 (sunny / rainy / hot / cold)", example = "rainy")
            @PathVariable("weather") String weather) {
        String menu = menuService.recommendByWeather(weather);

        if (MenuService.NOT_FOUND.equals(menu)) {
            return weather + "에 대한 " + menu + ". (sunny, rainy, hot, cold 중에서 골라 주세요)";
        }
        return weather + " 날씨에 어울리는 메뉴는 " + menu + "입니다.";
    }

    /**
     * 실습과제② 기분별 추천 — JSON(MenuResponse)으로 응답한다.
     *
     * 다른 과제와 달리 String이 아닌 객체를 반환하므로,
     * @RestController가 Jackson을 통해 JSON으로 직렬화한다.
     */
    @Operation(summary = "[과제②] 기분별 추천 (JSON)",
            description = "happy / sad / tired / stressed 에 따라 추천합니다. "
                    + "다른 과제와 달리 String이 아닌 MenuResponse 객체를 반환하므로 JSON으로 응답됩니다.")
    @GetMapping("/menu/mood/{mood}")
    public MenuResponse menuByMood(
            @Parameter(description = "기분 (happy / sad / tired / stressed)", example = "happy")
            @PathVariable("mood") String mood) {
        String menu = menuService.recommendByMood(mood);

        return new MenuResponse(
                mood,
                menu,
                MenuService.NOT_FOUND.equals(menu)
                        ? mood + "에 대한 " + menu + ". (happy, sad, tired, stressed 중에서 골라 주세요)"
                        : "기분이 " + mood + "일 땐 " + menu + " 어떠세요?"
        );
    }

    /**
     * 실습과제③ 가격대별 추천.
     *
     * 값을 주소 경로가 아니라 ?min=5000&max=10000 형태로 받으므로
     * @PathVariable 대신 @RequestParam을 사용한다.
     */
    @Operation(summary = "[과제③] 가격대별 추천 (@RequestParam)",
            description = "값을 경로가 아니라 쿼리 파라미터로 두 개 받습니다. max 기준으로 구간을 나눕니다. "
                    + "min이 max보다 크면 400 Bad Request를 반환합니다.")
    @GetMapping("/menu/price/search")
    public String menuByPrice(
            @Parameter(description = "최소 금액", example = "5000") @RequestParam("min") int min,
            @Parameter(description = "최대 금액", example = "10000") @RequestParam("max") int max) {
        if (min > max) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "min(" + min + ")은 max(" + max + ")보다 클 수 없습니다."
            );
        }

        String menu = menuService.recommendByPrice(max);

        return min + "~" + max + "원 가격대라면 " + menu + " 어떠세요?";
    }

    /**
     * 실습과제④ 나만의 추천 — 같이 먹는 사람을 기준으로 추천한다.
     */
    @Operation(summary = "[과제④] 나만의 추천 — 같이 먹는 사람 기준",
            description = "추천 기준을 '누구와 함께 먹는가'로 직접 설계했습니다. "
                    + "solo / friend / family 외의 값은 랜덤 추천으로 대체합니다.")
    @GetMapping("/menu/my/{companion}")
    public String menuByCompanion(
            @Parameter(description = "같이 먹는 사람 (solo / friend / family)", example = "solo")
            @PathVariable("companion") String companion) {
        String menu = menuService.recommendByCompanion(companion);

        return switch (companion) {
            case "solo" -> "혼자 먹기 좋은 " + menu + " 어떠세요?";
            case "friend" -> "친구랑 나눠 먹기 좋은 " + menu + " 어떠세요?";
            case "family" -> "가족과 함께라면 " + menu + " 어떠세요?";
            default -> "오늘은 " + menu + " 어떠세요?";
        };
    }
}
