package com.skala.stock.controller;

import com.skala.stock.dto.StockDto;
import com.skala.stock.service.StockService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
@Tag(name = "주식 관리", description = "주식 CRUD API")
public class StockController {

    private final StockService stockService;

    @PostMapping
    @Operation(summary = "주식 생성", description = "새로운 주식을 등록합니다")
    public ResponseEntity<StockDto> createStock(@Valid @RequestBody StockDto stockDto) {
        StockDto createdStock = stockService.createStock(stockDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdStock);
    }

    @GetMapping("/{id}")
    @Operation(summary = "주식 조회 (ID)", description = "ID로 주식을 조회합니다")
    public ResponseEntity<StockDto> getStockById(@PathVariable Long id) {
        StockDto stock = stockService.getStockById(id);
        return ResponseEntity.ok(stock);
    }

    @GetMapping
    @Operation(summary = "전체 주식 조회", description = "모든 주식을 조회합니다")
    public ResponseEntity<List<StockDto>> getAllStocks() {
        List<StockDto> stocks = stockService.getAllStocks();
        return ResponseEntity.ok(stocks);
    }
}
