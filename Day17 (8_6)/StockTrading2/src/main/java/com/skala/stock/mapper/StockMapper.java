package com.skala.stock.mapper;

import org.apache.ibatis.annotations.Mapper;
import com.skala.stock.dto.TradeSnapshotDto;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 집계·통계 쿼리를 담당하는 MyBatis 매퍼다.
 *
 * JPA는 엔티티 단위 CRUD에 강하지만, GROUP BY·CASE WHEN이 섞인
 * 집계 쿼리는 SQL을 직접 쓰는 편이 읽기 쉽고 의도가 분명하다.
 * 그래서 조회·수정은 JPA, 통계는 MyBatis로 나눠 썼다.
 *
 * 실제 SQL은 resources/mapper/StockMapper.xml 에 있다.
 */
@Mapper
public interface StockMapper {

    /** 종목별 매수/매도 수량·금액 집계 */
    List<TransactionStatisticsDto> selectTransactionStatistics(@Param("userId") Long userId);

    /** 일별 거래 집계 */
    List<DailyTradeDto> selectDailyTrades(@Param("userId") Long userId);

    /** 보유 주식의 현재 평가액 합계 (미보유 시 0) */
    Long selectHoldingValue(@Param("userId") Long userId);

    /** 보유 주식의 매입 원가 합계 (미보유 시 0) */
    Long selectHoldingCost(@Param("userId") Long userId);

    /**
     * 거래 시점의 총 자산·수익률 스냅샷을 한 번의 쿼리로 구한다.
     * 감사 로그에 "그때 자산이 얼마였는지"를 함께 남기기 위한 용도다.
     */
    TradeSnapshotDto selectTradeSnapshot(@Param("userId") Long userId);
}
