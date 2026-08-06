package com.skala.stock.mapper;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 일별 거래 집계 결과를 담는 DTO다.
 * MyBatis가 GROUP BY 결과를 이 타입으로 매핑한다.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyTradeDto {
    private String tradeDate;      // 거래일 (yyyy-MM-dd)
    private Long tradeCount;       // 그 날의 거래 건수
    private Long buyQuantity;      // 매수 수량 합계
    private Long sellQuantity;     // 매도 수량 합계
    private Long buyAmount;        // 매수 금액 합계
    private Long sellAmount;       // 매도 금액 합계
    private Long netAmount;        // 매도 - 매수 (현금 순증감)
}
