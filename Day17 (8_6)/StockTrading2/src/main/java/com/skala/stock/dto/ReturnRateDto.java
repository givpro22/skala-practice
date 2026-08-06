package com.skala.stock.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 총 수익률 조회 결과.
 *
 *   수익률(%) = 평가 손익 / 매입 원가 × 100
 *
 * 보유 주식이 없으면 매입 원가가 0이라 나눌 수 없으므로 0%로 본다.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReturnRateDto {
    private Long userId;
    private String username;
    private Long holdingCost;      // 매입 원가
    private Long holdingValue;     // 현재 평가액
    private Long evaluationProfit; // 평가 손익
    private Double returnRate;     // 수익률 (%)
}
