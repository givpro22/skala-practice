package com.example.menu.controller;

import com.example.menu.dto.MenuResponse;
import com.example.menu.service.MenuService;
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
public class MenuController {

    private final MenuService menuService;

    /**
     * Spring Container가 MenuService Bean을 생성자에 주입합니다.
     */
    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    @GetMapping("/hello/{name}")
    public String hello(@PathVariable("name") String name) {
        return name + "님, 오늘도 맛있는 하루 보내세요!";
    }

    @GetMapping("/menu")
    public String menu() {
        return "오늘의 추천 메뉴는 " + menuService.recommend() + "입니다.";
    }

    @GetMapping("/menu/random")
    public String randomMenu() {
        return "오늘은 " + menuService.randomMenu() + " 어떠세요?";
    }

    @GetMapping("/menu/{category}")
    public String menuByCategory(@PathVariable("category") String category) {
        String menu = menuService.recommendByCategory(category);
        return category + " 추천 메뉴는 " + menu + "입니다.";
    }

    @GetMapping("/menu/json/{category}")
    public MenuResponse menuJson(@PathVariable("category") String category) {
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
    @GetMapping("/menu/weather/{weather}")
    public String menuByWeather(@PathVariable("weather") String weather) {
        String menu = menuService.recommendByWeather(weather);

        if (MenuService.NOT_FOUND.equals(menu)) {
            return weather + "에 대한 " + menu + ". (sunny, rainy, hot, cold 중에서 골라 주세요)";
        }
        return weather + " 날씨에 어울리는 메뉴는 " + menu + "입니다.";
    }

    /**
     * 실습과제② 기분별 추천 — 문자열로 응답한다.
     */
    @GetMapping("/menu/mood/{mood}")
    public String menuByMood(@PathVariable("mood") String mood) {
        String menu = menuService.recommendByMood(mood);

        if (MenuService.NOT_FOUND.equals(menu)) {
            return mood + "에 대한 " + menu + ". (happy, sad, tired, stressed 중에서 골라 주세요)";
        }
        return "기분이 " + mood + "일 땐 " + menu + " 어떠세요?";
    }

    /**
     * 실습과제③ 가격대별 추천.
     *
     * 값을 주소 경로가 아니라 ?min=5000&max=10000 형태로 받으므로
     * @PathVariable 대신 @RequestParam을 사용한다.
     */
    @GetMapping("/menu/price/search")
    public String menuByPrice(@RequestParam("min") int min,
                              @RequestParam("max") int max) {
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
    @GetMapping("/menu/my/{companion}")
    public String menuByCompanion(@PathVariable("companion") String companion) {
        String menu = menuService.recommendByCompanion(companion);

        return switch (companion) {
            case "solo" -> "혼자 먹기 좋은 " + menu + " 어떠세요?";
            case "friend" -> "친구랑 나눠 먹기 좋은 " + menu + " 어떠세요?";
            case "family" -> "가족과 함께라면 " + menu + " 어떠세요?";
            default -> "오늘은 " + menu + " 어떠세요?";
        };
    }
}
