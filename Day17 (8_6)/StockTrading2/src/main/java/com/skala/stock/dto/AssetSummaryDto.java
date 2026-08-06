package com.skala.stock.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 총 자산 조회 결과.
 *
 *   총 자산 = 현금 잔액 + 보유 주식 평가액
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssetSummaryDto {
    private Long userId;
    private String username;
    private Long cashBalance;      // 현금 잔액
    private Long holdingValue;     // 보유 주식 평가액 (수량 × 현재가)
    private Long totalAssets;      // 현금 + 평가액
    private Long holdingCost;      // 보유 주식 매입 원가 (수량 × 평균 매수가)
    private Long evaluationProfit; // 평가 손익 (평가액 - 매입 원가)
}
