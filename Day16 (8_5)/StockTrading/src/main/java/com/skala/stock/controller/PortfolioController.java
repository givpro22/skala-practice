package com.skala.stock.controller;

import com.skala.stock.dto.PortfolioDto;
import com.skala.stock.service.PortfolioService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/portfolios")
@RequiredArgsConstructor
@Validated // @PathVariable 제약을 동작시키기 위해 필요
@Tag(name = "포트폴리오 관리", description = "포트폴리오 조회 API")
public class PortfolioController {

    private final PortfolioService portfolioService;

    @GetMapping("/user/{userId}")
    @Operation(summary = "사용자 포트폴리오 조회", description = "특정 사용자의 전체 포트폴리오를 조회합니다")
    public ResponseEntity<List<PortfolioDto>> getUserPortfolio(@PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        List<PortfolioDto> portfolios = portfolioService.getUserPortfolio(userId);
        return ResponseEntity.ok(portfolios);
    }

    @GetMapping("/user/{userId}/stock/{stockId}")
    @Operation(summary = "특정 주식 포트폴리오 조회", description = "사용자의 특정 주식 포트폴리오를 조회합니다")
    public ResponseEntity<PortfolioDto> getPortfolio(
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId,
            @PathVariable @Min(value = 1, message = "주식 ID는 1 이상이어야 합니다") Long stockId) {
        PortfolioDto portfolio = portfolioService.getPortfolio(userId, stockId);
        return ResponseEntity.ok(portfolio);
    }
}
