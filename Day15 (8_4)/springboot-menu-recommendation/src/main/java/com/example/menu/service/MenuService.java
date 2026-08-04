package com.example.menu.service;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 메뉴 추천 비즈니스 로직을 담당하는 Spring Bean입니다.
 *
 * @Service를 사용하면 Component Scan을 통해 Spring Container에
 * 자동으로 Bean으로 등록됩니다.
 */
@Service
public class MenuService {

    /**
     * 조건에 맞는 메뉴를 찾지 못했을 때 돌려주는 값입니다.
     * 문자열을 여기저기 직접 적으면 오타가 나기 쉬우므로 상수로 한 번만 정의합니다.
     */
    public static final String NOT_FOUND = "추천 가능한 메뉴가 없습니다";

    private final List<String> menus = List.of(
            "김치찌개",
            "불고기",
            "짜장면",
            "돈가스",
            "떡볶이",
            "치킨",
            "피자"
    );

    public String recommend() {
        return "김치찌개";
    }

    public String recommendByCategory(String category) {
        return switch (category) {
            case "korean" -> "불고기";
            case "chinese" -> "짜장면";
            case "japanese" -> "돈가스";
            case "snack" -> "떡볶이";
            default -> "추천 가능한 메뉴가 없습니다";
        };
    }

    public String randomMenu() {
        int index = ThreadLocalRandom.current().nextInt(menus.size());
        return menus.get(index);
    }

    public String recommendByWeather(String weather) {
        return switch (weather) {
            case "sunny" -> "비빔밥";
            case "rainy" -> "칼국수";
            case "hot" -> "냉면";
            case "cold" -> "김치찌개";
            default -> NOT_FOUND;
        };
    }

    public String recommendByMood(String mood) {
        return switch (mood) {
            case "happy" -> "치킨";
            case "sad" -> "떡볶이";
            case "tired" -> "삼계탕";
            case "stressed" -> "마라탕";
            default -> NOT_FOUND;
        };
    }

    /**
     * 가격 상한(max)을 기준으로 메뉴를 고릅니다.
     */
    public String recommendByPrice(int max) {
        if (max <= 6000) {
            return "김밥";
        }
        if (max <= 12000) {
            return "돈가스";
        }
        return "소고기 구이";
    }

    /**
     * 같이 먹는 사람에 따라 메뉴를 고릅니다.
     * 정해진 값이 아니면 menus 리스트에서 무작위로 하나 고릅니다.
     */
    public String recommendByCompanion(String companion) {
        return switch (companion) {
            case "solo" -> "라면";
            case "friend" -> "피자";
            case "family" -> "불고기";
            default -> randomMenu();
        };
    }
}
