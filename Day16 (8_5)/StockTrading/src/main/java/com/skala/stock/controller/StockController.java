package com.skala.stock.controller;

import com.skala.stock.dto.StockDto;
import com.skala.stock.service.StockService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
@Validated // @PathVariable 에 붙인 @Min · @NotBlank 를 동작시키기 위해 필요
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
    public ResponseEntity<StockDto> getStockById(
            @Parameter(description = "주식 ID", example = "1")
            @PathVariable @Min(value = 1, message = "ID는 1 이상이어야 합니다") Long id) {
        StockDto stock = stockService.getStockById(id);
        return ResponseEntity.ok(stock);
    }

    @GetMapping("/code/{code}")
    @Operation(summary = "주식 조회 (종목 코드)",
            description = "종목 코드로 주식을 조회합니다. 예) 005930")
    public ResponseEntity<StockDto> getStockByCode(
            @Parameter(description = "종목 코드", example = "005930")
            @PathVariable
            @NotBlank(message = "종목 코드는 비어 있을 수 없습니다")
            String code) {
        StockDto stock = stockService.getStockByCode(code);
        return ResponseEntity.ok(stock);
    }

    @GetMapping
    @Operation(summary = "전체 주식 조회", description = "모든 주식을 조회합니다")
    public ResponseEntity<List<StockDto>> getAllStocks() {
        List<StockDto> stocks = stockService.getAllStocks();
        return ResponseEntity.ok(stocks);
    }

    @PutMapping("/{id}")
    @Operation(summary = "주식 수정",
            description = "ID로 주식 정보를 수정합니다. 다른 종목이 쓰는 코드로는 바꿀 수 없습니다(409)")
    public ResponseEntity<StockDto> updateStock(
            @Parameter(description = "주식 ID", example = "1")
            @PathVariable @Min(value = 1, message = "ID는 1 이상이어야 합니다") Long id,
            @Valid @RequestBody StockDto stockDto) {
        StockDto updatedStock = stockService.updateStock(id, stockDto);
        return ResponseEntity.ok(updatedStock);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "주식 삭제",
            description = "ID로 주식을 삭제합니다. 포트폴리오·거래 내역이 참조 중이면 삭제할 수 없습니다(409)")
    public ResponseEntity<Void> deleteStock(
            @Parameter(description = "주식 ID", example = "1")
            @PathVariable @Min(value = 1, message = "ID는 1 이상이어야 합니다") Long id) {
        stockService.deleteStock(id);
        return ResponseEntity.noContent().build();
    }
}
