package com.example.demo.controller;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/api/hello")
    public String hello(
            @RequestParam(defaultValue = "Spring Boot") String name) {
        return "Hello, " + name + "!";
    }

    @GetMapping("/api/info")
    public Map<String, Object> info() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("application", "gradle-demo");
        result.put("message", "Spring Boot 실행 성공");
        result.put("time", LocalDateTime.now().toString());
        return result;
    }
}
