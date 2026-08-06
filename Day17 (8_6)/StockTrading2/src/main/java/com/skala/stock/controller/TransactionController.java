package com.skala.stock.controller;

import com.skala.stock.dto.TradeRequestDto;
import com.skala.stock.dto.TransactionDto;
import com.skala.stock.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
@Validated
@Tag(name = "거래 관리", description = "주식 매수/매도 거래 API")
public class TransactionController {

    private final TransactionService transactionService;

    @PostMapping("/trade")
    @Operation(summary = "주식 매매 실행",
            description = "매수(BUY) 또는 매도(SELL)를 실행합니다. "
                    + "잔액·보유 수량이 부족하면 400을 반환합니다")
    public ResponseEntity<TransactionDto> executeTrade(@Valid @RequestBody TradeRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(transactionService.executeTrade(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "거래 상세 조회", description = "거래 ID로 상세 내역을 조회합니다 (읽기 전용)")
    public ResponseEntity<TransactionDto> getTransactionById(
            @Parameter(description = "거래 ID", example = "1")
            @PathVariable @Min(value = 1, message = "ID는 1 이상이어야 합니다") Long id) {
        return ResponseEntity.ok(transactionService.getTransactionById(id));
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "사용자 거래 내역 조회", description = "특정 사용자의 전체 거래 내역을 최신순으로 조회합니다")
    public ResponseEntity<List<TransactionDto>> getUserTransactions(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId) {
        return ResponseEntity.ok(transactionService.getUserTransactions(userId));
    }

    @GetMapping("/user/{userId}/stock/{stockId}")
    @Operation(summary = "특정 주식 거래 내역 조회",
            description = "사용자가 특정 종목에 대해 남긴 거래 내역만 조회합니다")
    public ResponseEntity<List<TransactionDto>> getUserStockTransactions(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "사용자 ID는 1 이상이어야 합니다") Long userId,
            @Parameter(description = "주식 ID", example = "1")
            @PathVariable @Min(value = 1, message = "주식 ID는 1 이상이어야 합니다") Long stockId) {
        return ResponseEntity.ok(transactionService.getUserStockTransactions(userId, stockId));
    }
}
