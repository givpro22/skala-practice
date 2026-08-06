package com.skala.stock.controller;

import com.skala.stock.dto.AssetSummaryDto;
import com.skala.stock.dto.PortfolioDto;
import com.skala.stock.dto.ReturnRateDto;
import com.skala.stock.dto.TransactionDto;
import com.skala.stock.entity.TradeAuditLog;
import com.skala.stock.mapper.DailyTradeDto;
import com.skala.stock.mapper.TransactionStatisticsDto;
import com.skala.stock.service.StockAnalysisService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/analysis")
@RequiredArgsConstructor
@Validated
@Tag(name = "분석", description = "포트폴리오 평가·자산·수익률·거래 통계 API")
public class StockAnalysisController {

    private final StockAnalysisService analysisService;

    @GetMapping("/portfolio/{userId}")
    @Operation(summary = "[분석①] 포트폴리오 평가 손익 조회",
            description = "보유 종목별 평가 금액과 평가 손익을 조회합니다")
    public ResponseEntity<List<PortfolioDto>> getPortfolioProfitLoss(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getPortfolioProfitLoss(userId));
    }

    @GetMapping("/transactions/{userId}")
    @Operation(summary = "[분석②] 거래 내역 상세 조회",
            description = "사용자의 전체 거래 내역을 최신순으로 조회합니다")
    public ResponseEntity<List<TransactionDto>> getTransactionDetails(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getTransactionDetails(userId));
    }

    @GetMapping("/transactions/{userId}/stock/{stockId}")
    @Operation(summary = "[분석③] 특정 주식 거래 내역 조회",
            description = "사용자가 특정 종목에 대해 남긴 거래 내역만 조회합니다")
    public ResponseEntity<List<TransactionDto>> getStockTransactions(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId,
            @Parameter(description = "주식 ID", example = "1")
            @PathVariable @Min(value = 1, message = "주식 ID는 1 이상이어야 합니다") Long stockId) {
        return ResponseEntity.ok(analysisService.getStockTransactions(userId, stockId));
    }

    @GetMapping("/assets/{userId}")
    @Operation(summary = "[분석④] 총 자산 조회",
            description = "현금 잔액 + 보유 주식 평가액을 합산한 총 자산을 조회합니다")
    public ResponseEntity<AssetSummaryDto> getTotalAssets(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getTotalAssets(userId));
    }

    @GetMapping("/return-rate/{userId}")
    @Operation(summary = "[분석⑤] 총 수익률 조회",
            description = "평가 손익 ÷ 매입 원가 × 100 으로 수익률을 계산합니다")
    public ResponseEntity<ReturnRateDto> getTotalReturnRate(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getTotalReturnRate(userId));
    }

    @GetMapping("/statistics/{userId}")
    @Operation(summary = "[분석⑥] 거래 통계 조회",
            description = "종목별 매수/매도 수량·금액 집계입니다 (MyBatis GROUP BY)")
    public ResponseEntity<List<TransactionStatisticsDto>> getTransactionStatistics(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getTransactionStatistics(userId));
    }

    @GetMapping("/daily/{userId}")
    @Operation(summary = "[분석⑦] 일별 거래 내역 조회",
            description = "날짜별 거래 건수와 매수·매도 금액 집계입니다 (MyBatis GROUP BY)")
    public ResponseEntity<List<DailyTradeDto>> getDailyTrades(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getDailyTrades(userId));
    }

    @GetMapping("/audit/{userId}")
    @Operation(summary = "[분석⑧] 거래 감사 로그 조회",
            description = "AOP(TradeAuditAspect)가 매매 성공·실패 시마다 남긴 감사 로그입니다. "
                    + "실패한 거래도 별도 트랜잭션으로 기록되어 함께 조회됩니다")
    public ResponseEntity<List<TradeAuditLog>> getAuditLogs(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(analysisService.getAuditLogs(userId));
    }
}
